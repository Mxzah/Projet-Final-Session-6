module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders
    def index
      orders = Order.where(client_id: current_user.id)
                    .includes(:table, :order_lines)
                    .order(created_at: :desc)

      render json: {
        success: true,
        data: orders.map { |o| order_json(o) },
        errors: []
      }, status: :ok
    end

    # GET /api/orders/:id
    def show
      order = Order.includes(:table, :order_lines).find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: nil, errors: ["Order not found"] }, status: :ok
      end

      render json: {
        success: true,
        data: order_json(order),
        errors: []
      }, status: :ok
    end

    # POST /api/orders
    def create
      order = Order.new(order_params)
      order.client_id = current_user.id

      if order.save
        render json: {
          success: true,
          data: order_json(order),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: order.errors.full_messages
        }, status: :ok
      end
    end

    private

    def order_params
      params.require(:order).permit(:nb_people, :note, :table_id, :vibe_id)
    end

    def order_json(order)
      lines = order.order_lines.map do |l|
        {
          id: l.id,
          quantity: l.quantity,
          unit_price: l.unit_price.to_f,
          note: l.note,
          status: l.status,
          orderable_type: l.orderable_type,
          orderable_id: l.orderable_id,
          created_at: l.created_at
        }
      end

      total = lines.sum { |l| l[:unit_price] * l[:quantity] }

      {
        id: order.id,
        nb_people: order.nb_people,
        note: order.note,
        tip: order.tip.to_f,
        table_id: order.table_id,
        table_number: order.table&.number,
        client_id: order.client_id,
        server_id: order.server_id,
        vibe_id: order.vibe_id,
        created_at: order.created_at,
        ended_at: order.ended_at,
        order_lines: lines,
        total: total
      }
    end
  end
end
