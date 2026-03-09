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
      {
        columns: [
          { key: "table_number", label: "Table" },
          { key: "capacity", label: "Places" },
          { key: "nb_orders", label: "Nb commandes" },
          { key: "nb_people_total", label: "Personnes totales" },
          { key: "avg_people", label: "Moy. personnes" },
          { key: "revenue", label: "Revenu ($)" },
          { key: "total_tips", label: "Pourboires ($)" },
          { key: "grand_total", label: "Total ($)" },
          { key: "avg_revenue_per_order", label: "Rev. moy./commande ($)" },
          { key: "avg_duration_min", label: "Durée moy. (min)" },
          { key: "top_item", label: "Item #1" },
          { key: "top_vibe", label: "Vibe #1" }
        ],
        date_column: "o.created_at",
        category_column: "t.id",
        base_conditions: [],
        sql: ->(where_clause, extra) {
          sd = extra[:start_date].present? ? ActiveRecord::Base.connection.quote(extra[:start_date]) : nil
          ed = extra[:end_date].present? ? ActiveRecord::Base.connection.quote(extra[:end_date]) : nil

          date_cond = ""
          date_cond += " AND o.created_at >= #{sd}" if sd
          date_cond += " AND o.created_at <= #{ed}" if ed

          <<~SQL
            SELECT
              t.number                                             AS table_number,
              t.nb_seats                                           AS capacity,
              COUNT(DISTINCT o.id)                                 AS nb_orders,
              COALESCE(SUM(o.nb_people), 0)                        AS nb_people_total,
              ROUND(AVG(o.nb_people), 1)                           AS avg_people,
              COALESCE(ROUND(SUM(
                (SELECT COALESCE(SUM(ol.quantity * ol.unit_price), 0)
                 FROM order_lines ol WHERE ol.order_id = o.id)
              ), 2), 0)                                            AS revenue,
              COALESCE(ROUND(SUM(o.tip), 2), 0)                    AS total_tips,
              COALESCE(ROUND(SUM(
                (SELECT COALESCE(SUM(ol.quantity * ol.unit_price), 0)
                 FROM order_lines ol WHERE ol.order_id = o.id)
              ) + SUM(COALESCE(o.tip, 0)), 2), 0)                  AS grand_total,
              CASE WHEN COUNT(DISTINCT o.id) > 0
                THEN ROUND(SUM(
                  (SELECT COALESCE(SUM(ol.quantity * ol.unit_price), 0)
                   FROM order_lines ol WHERE ol.order_id = o.id)
                ) / COUNT(DISTINCT o.id), 2)
                ELSE 0
              END                                                  AS avg_revenue_per_order,
              ROUND(AVG(TIMESTAMPDIFF(MINUTE, o.created_at, o.ended_at)), 1) AS avg_duration_min,
              (SELECT sub_i.name
                 FROM order_lines sub_ol
                 JOIN items sub_i ON sub_i.id = sub_ol.orderable_id AND sub_ol.orderable_type = 'Item'
                 JOIN orders sub_o ON sub_o.id = sub_ol.order_id AND sub_o.deleted_at IS NULL
                WHERE sub_o.table_id = t.id#{date_cond.gsub('o.', 'sub_o.')}
                GROUP BY sub_i.id, sub_i.name
                ORDER BY SUM(sub_ol.quantity) DESC LIMIT 1)        AS top_item,
              (SELECT sub_v.name
                 FROM orders sub_o
                 JOIN vibes sub_v ON sub_v.id = sub_o.vibe_id
                WHERE sub_o.table_id = t.id AND sub_o.deleted_at IS NULL#{date_cond.gsub('o.', 'sub_o.')}
                GROUP BY sub_v.id, sub_v.name
                ORDER BY COUNT(*) DESC LIMIT 1)                    AS top_vibe,
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
