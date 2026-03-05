module Api
  class CuisineController < ApiController
    before_action :authenticate_user!
    before_action :authorize_kitchen_staff!
    before_action :set_line,  only: [ :next_status, :update_line, :destroy_line ]
    before_action :set_order, only: [ :release_order, :assign_server ]

    # GET /api/kitchen/orders
    def orders
      active_orders = Order.where(ended_at: nil)
                           .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                           .order(created_at: :asc)

      all_lines = active_orders.flat_map(&:order_lines)
      item_ids  = all_lines.select { |l| l.orderable_type == "Item" }.map(&:orderable_id).uniq
      combo_ids = all_lines.select { |l| l.orderable_type == "Combo" }.map(&:orderable_id).uniq
      items_map  = Item.where(id: item_ids).index_by(&:id)
      combos_map = Combo.where(id: combo_ids).index_by(&:id)

      render_success(data: active_orders.map { |o| order_json(o, items_map, combos_map) }, errors: [])
    end

    # PUT /api/kitchen/order_lines/:id/next_status  (all kitchen staff)
    def next_status
      unless @line.order.server_id.present?
        return render_error(I18n.t("controllers.cuisine.server_not_assigned"))
      end

      current_index = OrderLine::STATUS_ORDER[@line.status]
      next_s = OrderLine::STATUSES[current_index + 1]

      unless next_s
        return render_error(I18n.t("controllers.cuisine.already_at_final_status"))
      end

      if next_s == "served"
        return render_error(I18n.t("controllers.cuisine.only_server_can_serve"))
      end

      if @line.update(status: next_s)
        render_success(data: line_json(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # PUT /api/kitchen/order_lines/:id  (waiter/admin only - quantity and note)
    def update_line
      return render_error(I18n.t("controllers.cuisine.unauthorized")) unless senior_staff?

      if @line.status == "served"
        return render_error(I18n.t("controllers.cuisine.cannot_modify_line", status: @line.status))
      end

      if @line.update(line_update_params)
        render_success(data: line_json(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # DELETE /api/kitchen/order_lines/:id  (waiter/admin only - hard delete)
    def destroy_line
      return render_error(I18n.t("controllers.cuisine.unauthorized")) unless senior_staff?

      unless %w[sent in_preparation].include?(@line.status)
        return render_error(I18n.t("controllers.cuisine.cannot_delete_line", status: @line.status))
      end

      if @line.destroy
        render_success(data: [], errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # POST /api/kitchen/orders/:id/release  (waiter/admin only — close order, free table)
    def release_order
      return render_error(I18n.t("controllers.cuisine.unauthorized")) unless senior_staff?

      if @order.ended_at.present?
        return render_error(I18n.t("controllers.cuisine.order_already_closed"))
      end

      @order.update!(ended_at: Time.current)
      render_success(data: [], errors: [])
    end

    # POST /api/kitchen/orders/:id/assign_server  (waiter/admin only)
    def assign_server
      return render_error(I18n.t("controllers.cuisine.unauthorized")) unless senior_staff?

      @order.update!(server: current_user)
      render_success(data: [], errors: [])
    end

    private

    def authorize_kitchen_staff!
      unless %w[Administrator Waiter Cook].include?(current_user.type)
        render_error(I18n.t("controllers.cuisine.unauthorized"))
      end
    end

    def senior_staff?
      %w[Administrator Waiter].include?(current_user.type)
    end

    def line_update_params
      # Only quantity and note - status is handled by next_status endpoint
      params.require(:order_line).permit(:quantity, :note)
    end

    def line_json(line)
      {
        id: line.id,
        quantity: line.quantity,
        unit_price: line.unit_price.to_f,
        note: line.note,
        status: line.status,
        orderable_type: line.orderable_type,
        orderable_id: line.orderable_id,
        orderable_name: line.orderable&.name
      }
    end

    def set_order
      @order = Order.find_by(id: params[:id])
      render_error(I18n.t("controllers.cuisine.order_not_found")) unless @order
    end

    def set_line
      @line = OrderLine.find_by(id: params[:id])
      render_error(I18n.t("controllers.cuisine.order_line_not_found")) unless @line
    end

    def order_json(order, items_map, combos_map)
      # Kitchen only sees lines that have been sent (not waiting)
      visible_lines = order.order_lines.reject { |l| l.status == "waiting" }
      lines = visible_lines.map do |l|
        orderable = find_orderable(l.orderable_type, l.orderable_id, items_map, combos_map)
        {
          id: l.id,
          quantity: l.quantity,
          unit_price: l.unit_price.to_f,
          note: l.note,
          status: l.status,
          orderable_type: l.orderable_type,
          orderable_id: l.orderable_id,
          orderable_name: orderable&.name
        }
      end

      {
        id: order.id,
        nb_people: order.nb_people,
        note: order.note,
        tip: order.tip.to_f,
        vibe_name: order.vibe&.name,
        vibe_color: order.vibe&.color,
        table_number: order.table&.number,
        server_id: order.server_id,
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : nil,
        created_at: order.created_at,
        order_lines: lines
      }
    end

    def find_orderable(type, id, items_map, combos_map)
      return nil unless type.present? && id.present?
      return items_map[id]  if type == "Item"
      return combos_map[id] if type == "Combo"
      nil
    end
  end
end
