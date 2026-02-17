module Api
  class CuisineController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_kitchen_staff!

    # GET /api/cuisine/orders
    def orders
      active_orders = Order.where(ended_at: nil)
                           .includes(:table, :client, :server, :order_lines)
                           .order(created_at: :asc)

      render json: {
        success: true,
        data: active_orders.map { |o| order_json(o) },
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

    def order_json(order)
      lines = order.order_lines.map do |l|
        orderable = find_orderable(l.orderable_type, l.orderable_id)
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
        table_number: order.table&.number,
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : nil,
        created_at: order.created_at,
        order_lines: lines
      }
    end

    def find_orderable(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end
  end
end
