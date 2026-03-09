# frozen_string_literal: true

module Api
  # CRUD operations for customer orders
  class OrdersController < ApiController
    include StatsReportable

    before_action :authenticate_user!
    before_action :set_order, only: %i[show update pay destroy]
    skip_before_action :authenticate_user!, only: [:stats]
    before_action :authenticate_admin!, only: [:stats]

    # GET /api/orders — All orders for the current user
    def index
      orders = current_user.orders_as_client
                           .includes(:table, :vibe, :server, order_lines: :orderable)

      # Search by item name, combo name, server name, vibe name, or table number
      if params[:search].present?
        term = "%#{params[:search]}%"
        matching_ids = current_user.orders_as_client
                                   .joins(
                                     "LEFT JOIN order_lines item_lines " \
                                     "ON item_lines.order_id = orders.id AND item_lines.orderable_type = 'Item'"
                                   )
                                   .joins("LEFT JOIN items ON items.id = item_lines.orderable_id")
                                   .joins(
                                     "LEFT JOIN order_lines combo_lines " \
                                     "ON combo_lines.order_id = orders.id AND combo_lines.orderable_type = 'Combo'"
                                   )
                                   .joins("LEFT JOIN combos ON combos.id = combo_lines.orderable_id")
                                   .joins("LEFT JOIN users  servers ON servers.id = orders.server_id")
                                   .joins("LEFT JOIN vibes  ON vibes.id  = orders.vibe_id")
                                   .joins("LEFT JOIN tables ON tables.id = orders.table_id")
                                   .where(
                                     "items.name ILIKE :t OR combos.name ILIKE :t OR vibes.name ILIKE :t " \
                                     "OR CAST(tables.number AS TEXT) ILIKE :t " \
                                     "OR servers.first_name ILIKE :t OR servers.last_name ILIKE :t " \
                                     "OR CONCAT(servers.first_name, ' ', servers.last_name) ILIKE :t",
                                     t: term
                                   )
                                   .distinct.pluck(:id)
        orders = orders.where(id: matching_ids)
      end

      # Filter: only closed orders (history)
      orders = orders.where.not(ended_at: nil) if params[:closed] == "true"

      # Sort
      orders = case params[:sort]
      when "oldest"
                 orders.order(created_at: :asc)
      when "total_asc"
                 orders.order(created_at: :desc) # sorted client-side for computed total
      when "total_desc"
                 orders.order(created_at: :desc) # sorted client-side for computed total
      else
                 orders.order(created_at: :desc)
      end

      render_success(data: orders.map { |o| order_with_images(o) }, errors: [])
    end

    # GET /api/orders/:id — Show one order for the current user
    def show
      render_success(data: order_with_images(@order), errors: [])
    end

    # POST /api/orders
    def create
      order = Order.new(order_params)
      order.client = current_user

      # Validate server_id is actually a Waiter if provided
      if order.server_id.present?
        waiter = User.find_by(id: order.server_id)
        order.server_id = nil unless waiter&.type == "Waiter"
      end

      if order.save
        render_success(data: order.as_json, errors: [])
      else
        render_error(order.errors.full_messages)
      end
    end

    # POST /api/orders/close_open — Close all open orders for the current user
    def close_open
      current_user.orders_as_client.open.each { |o| o.update(ended_at: Time.current) }

      render_success(data: [], errors: [])
    end

    # GET /api/orders/stats — Override concern to add detail data
    def stats
      config = stats_config
      conditions = (config[:base_conditions] || []).dup
      binds = []

      if params[:start_date].present?
        conditions << "#{config[:date_column]} >= ?"
        binds << params[:start_date]
      end
      if params[:end_date].present?
        conditions << "#{config[:date_column]} <= ?"
        binds << params[:end_date]
      end
      if params[:category_ids].present?
        ids = Array(params[:category_ids]).map(&:to_i)
        conditions << "#{config[:category_column]} IN (#{ids.map { '?' }.join(', ')})"
        binds.concat(ids)
      end

      where_clause = conditions.any? ? "WHERE #{conditions.join(' AND ')}" : ""
      sanitized_where = ActiveRecord::Base.sanitize_sql_array([where_clause] + binds)

      sql = config[:sql].call(sanitized_where)
      rows = ActiveRecord::Base.connection.exec_query(sql).to_a

      # Detail data — all matching orders grouped by table
      detail_orders = Order.unscoped.where(deleted_at: nil)
                           .includes(:table, :vibe, :server, order_lines: :orderable)
      detail_orders = detail_orders.where("orders.created_at >= ?", params[:start_date]) if params[:start_date].present?
      detail_orders = detail_orders.where("orders.created_at <= ?", params[:end_date]) if params[:end_date].present?
      detail_orders = detail_orders.where(vibe_id: Array(params[:category_ids]).map(&:to_i)) if params[:category_ids].present?

      details = detail_orders.order(:table_id, created_at: :desc).group_by(&:table_id).map do |table_id, orders|
        {
          table_id: table_id,
          table_number: orders.first.table.number,
          orders: orders.map { |o| order_detail_json(o) }
        }
      end

      render_success(data: { columns: config[:columns], rows: rows, details: details })
    end

    # PUT /api/orders/:id
    def update
      if @order.update(order_update_params)
        render_success(data: @order.reload.as_json, errors: [])
      else
        render_error(@order.errors.full_messages)
      end
    end

    # POST /api/orders/:id/pay
    def pay
      return render_error(I18n.t("controllers.orders.already_closed")) if @order.ended_at.present?

      return render_error(I18n.t("controllers.orders.not_all_served")) unless @order.order_lines.all?(&:served?)

      tip_value = params[:tip].to_f

      return render_error(I18n.t("controllers.orders.tip_negative")) if tip_value.negative?

      return render_error(I18n.t("controllers.orders.tip_too_high")) if tip_value > 999.99

      @order.tip = tip_value
      @order.ended_at = Time.current

      if @order.save(validate: false)
        render_success(data: @order.reload.as_json, errors: [])
      else
        render_error(@order.errors.full_messages)
      end
    end

    # DELETE /api/orders/:id (hard delete, dependent: :destroy handles order_lines)
    def destroy
      @order.destroy
      render_success(data: [], errors: [])
    end

    private

    def order_params
      params.require(:order).permit(:nb_people, :note, :table_id, :vibe_id, :tip, :server_id)
    end

    def order_update_params
      params.require(:order).permit(:note)
    end

    def set_order
      @order = current_user.orders_as_client
                           .includes(:table, :vibe, :server, order_lines: :orderable)
                           .find_by(id: params[:id])
      render_error(I18n.t("controllers.orders.not_found")) unless @order
    end

    # Add image data (hash format) to order and each order line
    def order_with_images(order)
      data = order.as_json
      data[:vibe_image] = if order.vibe&.image&.attached?
                            blob = order.vibe.image.blob
                            {
                              url: rails_storage_proxy_path(order.vibe.image),
                              filename: blob.filename.to_s,
                              content_type: blob.content_type,
                              byte_size: blob.byte_size
                            }
      end
      data[:order_lines] = order.order_lines.map do |line|
        ld = line.as_json
        if line.orderable.respond_to?(:image) && line.orderable&.image&.attached?
          blob = line.orderable.image.blob
          ld[:image] = {
            url: rails_storage_proxy_path(line.orderable.image),
            filename: blob.filename.to_s,
            content_type: blob.content_type,
            byte_size: blob.byte_size
          }
        end
        ld
      end
      data
    end

    def authenticate_admin!
      authenticate_user!
      return if current_user&.type == "Administrator"

      render_error(I18n.t("controllers.admin.access_restricted"))
    end

    def order_detail_json(order)
      lines = order.order_lines.map do |l|
        {
          name: l.orderable&.name || "—",
          quantity: l.quantity,
          unit_price: l.unit_price.to_f,
          total: (l.quantity * l.unit_price).to_f.round(2),
          status: l.status,
          note: l.note
        }
      end

      {
        id: order.id,
        created_at: order.created_at,
        ended_at: order.ended_at,
        nb_people: order.nb_people,
        tip: (order.tip || 0).to_f,
        revenue: lines.sum { |l| l[:total] }.round(2),
        vibe_name: order.vibe&.name || "—",
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : "—",
        note: order.note,
        order_lines: lines
      }
    end

    def stats_config
      {
        columns: [
          { key: "table_number", label: "Table" },
          { key: "vibe_name", label: "Vibe" },
          { key: "server_name", label: "Serveur" },
          { key: "nb_orders", label: "Nb commandes" },
          { key: "nb_lines", label: "Nb lignes" },
          { key: "total_qty", label: "Qté totale" },
          { key: "avg_qty", label: "Qté moy." },
          { key: "revenue", label: "Revenu ($)" },
          { key: "total_tips", label: "Pourboires ($)" },
          { key: "grand_total", label: "Total tips+revenu ($)" },
          { key: "avg_line_price", label: "Prix moy. ligne ($)" },
          { key: "top_item", label: "Item #1" },
          { key: "top_combo", label: "Combo #1" },
          { key: "avg_duration_min", label: "Durée moy. (min)" }
        ],
        date_column: "o.created_at",
        category_column: "o.vibe_id",
        base_conditions: [ "o.deleted_at IS NULL" ],
        sql: ->(where_clause) {
          <<~SQL
            SELECT
              sub.table_number,
              sub.vibe_name,
              sub.server_name,
              COUNT(*)                                               AS nb_orders,
              SUM(sub.line_count)                                    AS nb_lines,
              SUM(sub.total_qty)                                     AS total_qty,
              ROUND(AVG(sub.avg_qty), 2)                             AS avg_qty,
              ROUND(SUM(sub.revenue), 2)                             AS revenue,
              ROUND(SUM(sub.tip), 2)                                 AS total_tips,
              ROUND(SUM(sub.revenue) + SUM(sub.tip), 2)              AS grand_total,
              ROUND(AVG(sub.avg_price), 2)                           AS avg_line_price,
              sub.top_item,
              sub.top_combo,
              ROUND(AVG(sub.duration_min), 1)                        AS avg_duration_min
            FROM (
              SELECT
                o.id                                                 AS order_id,
                t.id                                                 AS table_id,
                t.number                                             AS table_number,
                COALESCE(v.name, '—')                                AS vibe_name,
                COALESCE(CONCAT(srv.first_name, ' ', srv.last_name), '—') AS server_name,
                COALESCE(o.tip, 0)                                   AS tip,
                COALESCE((SELECT COUNT(*)              FROM order_lines ol2 WHERE ol2.order_id = o.id), 0) AS line_count,
                COALESCE((SELECT SUM(ol2.quantity)     FROM order_lines ol2 WHERE ol2.order_id = o.id), 0) AS total_qty,
                COALESCE((SELECT ROUND(AVG(ol2.quantity), 2) FROM order_lines ol2 WHERE ol2.order_id = o.id), 0) AS avg_qty,
                COALESCE((SELECT SUM(ol2.quantity * ol2.unit_price) FROM order_lines ol2 WHERE ol2.order_id = o.id), 0) AS revenue,
                (SELECT AVG(ol2.unit_price)            FROM order_lines ol2 WHERE ol2.order_id = o.id) AS avg_price,
                TIMESTAMPDIFF(MINUTE, o.created_at, o.ended_at)      AS duration_min,
                (SELECT sub_i.name
                   FROM order_lines sub_ol
                   JOIN items sub_i ON sub_i.id = sub_ol.orderable_id AND sub_ol.orderable_type = 'Item'
                  WHERE sub_ol.order_id = o.id
                  GROUP BY sub_i.id, sub_i.name ORDER BY SUM(sub_ol.quantity) DESC LIMIT 1) AS top_item,
                (SELECT sub_c.name
                   FROM order_lines sub_ol
                   JOIN combos sub_c ON sub_c.id = sub_ol.orderable_id AND sub_ol.orderable_type = 'Combo'
                  WHERE sub_ol.order_id = o.id
                  GROUP BY sub_c.id, sub_c.name ORDER BY SUM(sub_ol.quantity) DESC LIMIT 1) AS top_combo
              FROM orders o
              JOIN tables t   ON t.id = o.table_id
              LEFT JOIN vibes v    ON v.id = o.vibe_id
              LEFT JOIN users srv  ON srv.id = o.server_id
              #{where_clause}
            ) sub
            GROUP BY sub.table_id, sub.table_number, sub.vibe_name, sub.server_name, sub.top_item, sub.top_combo
            ORDER BY sub.table_number ASC
          SQL
        }
      }
    end
  end
end
