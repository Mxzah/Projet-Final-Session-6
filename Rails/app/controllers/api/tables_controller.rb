module Api
  class TablesController < AdminController
    skip_before_action :authenticate_user!, only: [:index, :show, :qr_code]
    skip_before_action :require_admin!, only: [:index, :show, :qr_code, :mark_cleaned]
    before_action :require_cleaning_staff!, only: [:mark_cleaned]

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
      tables = Table.all

      # Search by number
      if params[:search].present?
        tables = tables.where("tables.number = ?", params[:search].to_i)
      end

      # Filter by capacity
      if params[:capacity_min].present?
        tables = tables.where("tables.nb_seats >= ?", params[:capacity_min].to_i)
      end
      if params[:capacity_max].present?
        tables = tables.where("tables.nb_seats <= ?", params[:capacity_max].to_i)
      end

      # Sort
      case params[:sort]
      when "asc"
        tables = tables.order(nb_seats: :asc)
      when "desc"
        tables = tables.order(nb_seats: :desc)
      else
        tables = tables.order(:number)
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
        }, status: :created
      else
        render json: {
          success: false,
          data: nil,
          errors: table.errors.full_messages
        }, status: :unprocessable_entity
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
        }, status: :unprocessable_entity
      end
    end

    def destroy
      table = Table.find(params[:id])

      table.soft_delete

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
          errors: ["Invalid cleaned_at datetime"]
        }, status: :unprocessable_entity
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
        }, status: :unprocessable_entity
      end
    end

    private

    def table_params
      params.require(:table).permit(:number, :nb_seats)
    end

    def table_json(table)
      {
        id: table.id,
        number: table.number,
        capacity: table.nb_seats,
        status: table.orders.where(ended_at: nil).any? ? 'occupied' : 'available',
        qr_token: table.temporary_code
      }
    end

    def require_cleaning_staff!
      return if %w[Administrator Waiter].include?(current_user&.type)

      render json: {
        success: false,
        data: nil,
        errors: ["Access restricted to cleaning staff"]
      }, status: :ok
    end
  end
end
