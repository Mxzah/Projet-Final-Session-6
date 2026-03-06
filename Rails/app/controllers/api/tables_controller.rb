# frozen_string_literal: true

module Api
  # CRUD operations for restaurant tables
  class TablesController < AdminController
    skip_before_action :authenticate_user!, only: %i[index show qr_code]
    skip_before_action :require_admin!, only: %i[index show qr_code mark_cleaned]
    before_action :require_cleaning_staff!, only: [ :mark_cleaned ]

    def show
      table = Table.find_by!(temporary_code: params[:qr_token])

      render json: {
        success: true,
        data: table_json(table),
        errors: []
      }, status: :ok
    end

    # GET /api/tables?search=…&sort=asc|desc&capacity_min=…&capacity_max=…
    def index
      tables = Table.includes(:availabilities, orders: []).all

      # Search by number
      tables = tables.where("tables.number = ?", params[:search].to_i) if params[:search].present?

      # Filter by capacity
      tables = tables.where("tables.nb_seats >= ?", params[:capacity_min].to_i) if params[:capacity_min].present?
      tables = tables.where("tables.nb_seats <= ?", params[:capacity_max].to_i) if params[:capacity_max].present?

      # Sort
      tables = case params[:sort]
      when "asc"
                 tables.order(nb_seats: :asc)
      when "desc"
                 tables.order(nb_seats: :desc)
      else
                 tables.order(:number)
      end

      render json: {
        success: true,
        data: tables.map { |t| table_json(t) },
        errors: []
      }, status: :ok
    end

    def create
      table = Table.new(table_params)
      table.temporary_code = SecureRandom.hex(16)

      if table.save
        render json: {
          success: true,
          data: table_json(table),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: table.errors.full_messages
        }, status: :ok
      end
    end

    def update
      table = Table.find(params[:id])

      if table.update(table_params)
        render json: {
          success: true,
          data: table_json(table),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: table.errors.full_messages
        }, status: :ok
      end
    end

    def destroy
      table = Table.find(params[:id])

      table.soft_delete!

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    def qr_code
      table = Table.find_by!(temporary_code: params[:qr_token])

      qr_url = "#{request.base_url}/table/#{table.temporary_code}"
      qrcode = RQRCode::QRCode.new(qr_url)
      svg = qrcode.as_svg(
        color: "1B1A17",
        shape_rendering: "crispEdges",
        module_size: 6,
        standalone: true,
        use_path: true
      )

      render json: {
        success: true,
        data: {
          table_number: table.number,
          qr_url: qr_url,
          svg: svg
        },
        errors: []
      }, status: :ok
    end

    def mark_cleaned
      table = Table.find(params[:id])

      cleaned_time = begin
        params[:cleaned_at].present? ? Time.zone.parse(params[:cleaned_at].to_s) : Time.current
      rescue ArgumentError, TypeError
        nil
      end

      if cleaned_time.nil?
        render json: {
          success: false,
          data: nil,
          errors: [ I18n.t("controllers.tables.invalid_cleaned_at") ]
        }, status: :ok
        return
      end

      if table.mark_cleaned!(cleaned_time: cleaned_time)
        render json: {
          success: true,
          data: table_json(table),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: table.errors.full_messages
        }, status: :ok
      end
    end

    private

    def table_params
      params.require(:table).permit(:number, :nb_seats)
    end

    def table_json(table)
      open_order = table.orders.find_by(ended_at: nil)
      server = open_order&.server
      {
        id: table.id,
        number: table.number,
        capacity: table.nb_seats,
        status: open_order ? "occupied" : "available",
        qr_token: table.temporary_code,
        has_open_order: open_order.present?,
        open_order_server_id: open_order&.server_id,
        open_order_vibe_id: open_order&.vibe_id,
        server_name: server ? "#{server.first_name} #{server.last_name}" : nil,
        availabilities: table.availabilities.map do |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at, description: a.description }
        end
      }
    end

    def require_cleaning_staff!
      return if %w[Administrator Waiter].include?(current_user&.type)

      render json: {
        success: false,
        data: nil,
        errors: [ I18n.t("controllers.tables.cleaning_staff_only") ]
      }, status: :ok
    end
  end
end
