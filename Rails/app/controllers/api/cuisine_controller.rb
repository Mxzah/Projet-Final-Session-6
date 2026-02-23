module Api
  class CuisineController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_kitchen_staff!

    # GET /api/kitchen/orders
    def orders
      active_orders = Order.where(ended_at: nil)
                           .includes(:table, :client, :server, :order_lines, :vibe)
                           .order(created_at: :asc)

      all_lines = active_orders.flat_map(&:order_lines)
      item_ids  = all_lines.select { |l| l.orderable_type == 'Item' }.map(&:orderable_id).uniq
      combo_ids = all_lines.select { |l| l.orderable_type == 'Combo' }.map(&:orderable_id).uniq
      items_map  = Item.where(id: item_ids).index_by(&:id)
      combos_map = Combo.where(id: combo_ids).index_by(&:id)

      render json: {
        code: 200,
        success: true,
        data: active_orders.map { |o| order_json(o, items_map, combos_map) },
        errors: []
      }, status: :ok
    end

    # PUT /api/kitchen/order_lines/:id/next_status  (all kitchen staff)
    def next_status
      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok
      end

      current_index = OrderLine::STATUS_ORDER[line.status]
      next_s = OrderLine::STATUSES[current_index + 1]

      unless next_s
        return render json: { code: 200, success: false, data: [], errors: ["Already at final status"] }, status: :ok
      end

      if line.update(status: next_s)
        render json: {
          code: 200,
          success: true,
          data: [line_json(line.reload)],
          errors: []
        }, status: :ok
      else
        render json: {
          code: 200,
          success: false,
          data: [],
          errors: line.errors.full_messages
        }, status: :ok
      end
    end

    # PUT /api/kitchen/order_lines/:id  (waiter/admin only - quantity and note)
    def update_line
      return render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok unless senior_staff?

      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok
      end

      if line.update(line_update_params)
        render json: {
          code: 200,
          success: true,
          data: [line_json(line.reload)],
          errors: []
        }, status: :ok
      else
        render json: {
          code: 200,
          success: false,
          data: [],
          errors: line.errors.full_messages
        }, status: :ok
      end
    end

    # DELETE /api/kitchen/order_lines/:id  (waiter/admin only)
    def destroy_line
      return render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok unless senior_staff?

      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok
      end

      line.destroy

      render json: {
        code: 200,
        success: true,
        data: [],
        errors: []
      }, status: :ok
    end

    private

    def authorize_kitchen_staff!
      unless %w[Administrator Waiter Cook].include?(current_user.type)
        render json: {
          code: 200,
          success: false,
          data: [],
          errors: ["Unauthorized"]
        }, status: :ok
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
      orderable = find_orderable_by_type(line.orderable_type, line.orderable_id)
      {
        id: line.id,
        quantity: line.quantity,
        unit_price: line.unit_price.to_f,
        note: line.note,
        status: line.status,
        orderable_type: line.orderable_type,
        orderable_id: line.orderable_id,
        orderable_name: orderable&.name
      }
    end

    def find_orderable_by_type(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end

    def order_json(order, items_map, combos_map)
      lines = order.order_lines.map do |l|
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
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : nil,
        created_at: order.created_at,
        order_lines: lines
      }
    end

    def find_orderable(type, id, items_map, combos_map)
      return nil unless type.present? && id.present?
      return items_map[id]  if type == 'Item'
      return combos_map[id] if type == 'Combo'
      nil
    end
  end
end
