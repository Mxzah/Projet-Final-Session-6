# frozen_string_literal: true

module Api
  # CRUD operations for restaurant tables
  class TablesController < AdminController
    include StatsReportable

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

    def stats_config
      server_ids = params[:category_ids].present? ? Array(params[:category_ids]).map(&:to_i) : []

      {
        columns: [
          { key: "table_number", label: I18n.t("stats.tables.table_number") },
          { key: "capacity", label: I18n.t("stats.tables.capacity") },
          { key: "nb_orders", label: I18n.t("stats.tables.nb_orders") },
          { key: "nb_distinct_clients", label: I18n.t("stats.tables.nb_distinct_clients") },
          { key: "avg_people", label: I18n.t("stats.tables.avg_people") },
          { key: "avg_duration_min", label: I18n.t("stats.tables.avg_duration_min") },
          { key: "top_vibe", label: I18n.t("stats.tables.top_vibe") },
          { key: "usage_pct", label: I18n.t("stats.tables.usage_pct") }
        ],
        date_column: "o.created_at",
        category_column: "o.server_id",
        base_conditions: [],
        sql: ->(where_clause, extra) {
          sd = extra[:start_date].present? ? ActiveRecord::Base.connection.quote(extra[:start_date]) : nil
          ed = extra[:end_date].present? ? ActiveRecord::Base.connection.quote(extra[:end_date]) : nil

          date_cond = ""
          date_cond += " AND o.created_at >= #{sd}" if sd
          date_cond += " AND o.created_at <= #{ed}" if ed

          server_cond = ""
          if server_ids.any?
            safe_ids = server_ids.map { |id| ActiveRecord::Base.connection.quote(id) }.join(", ")
            server_cond = " AND o2.server_id IN (#{safe_ids})"
          end

          # Total orders (with same filters) for % utilization
          total_orders_sql = <<~TSQL
            SELECT COUNT(DISTINCT o2.id)
            FROM orders o2
            WHERE o2.deleted_at IS NULL
            #{date_cond.gsub('o.', 'o2.')}
            #{server_cond}
          TSQL
          total_count = ActiveRecord::Base.connection.select_value(total_orders_sql).to_f
          total_count = 1.0 if total_count.zero?

          <<~SQL
            SELECT
              t.number                                             AS table_number,
              t.nb_seats                                           AS capacity,
              COUNT(DISTINCT o.id)                                 AS nb_orders,
              COUNT(DISTINCT o.client_id)                          AS nb_distinct_clients,
              ROUND(AVG(o.nb_people), 1)                           AS avg_people,
              ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.created_at, o.ended_at)), 1) AS avg_duration_min,
              (SELECT CONCAT(sub_v.name, ' (', COUNT(*), ')')
                 FROM orders sub_o
                 JOIN vibes sub_v ON sub_v.id = sub_o.vibe_id
                WHERE sub_o.table_id = t.id AND sub_o.deleted_at IS NULL#{date_cond.gsub('o.', 'sub_o.')}
                GROUP BY sub_v.id, sub_v.name
                ORDER BY COUNT(*) DESC LIMIT 1)                    AS top_vibe,
              ROUND(COUNT(DISTINCT o.id) / #{total_count} * 100, 1) AS usage_pct,
              CASE WHEN t.deleted_at IS NOT NULL THEN 1 ELSE 0 END AS is_deleted
            FROM tables t
            LEFT JOIN orders o ON o.table_id = t.id
              AND o.deleted_at IS NULL
              #{date_cond}
            #{where_clause}
            GROUP BY t.id, t.number, t.nb_seats, t.deleted_at
            ORDER BY is_deleted ASC, nb_orders DESC
          SQL
        }
      }
    end
  end
end
