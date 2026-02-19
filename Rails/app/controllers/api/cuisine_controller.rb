module Api
  class CuisineController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_kitchen_staff!

    # GET /api/cuisine/orders
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
        success: true,
        data: active_orders.map { |o| order_json(o, items_map, combos_map) },
        errors: []
      }, status: :ok
    end

    private

    def authorize_kitchen_staff!
      allowed = %w[Administrator Waiter Cook].include?(current_user.type)

      unless allowed
        render json: {
          success: false,
          data: [],
          errors: ["Unauthorized"]
        }, status: :ok
      end
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
