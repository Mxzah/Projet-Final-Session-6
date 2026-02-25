module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders — All orders for the current user
    def index
      orders = Order.where(client_id: current_user.id)
                    .includes(:table, :vibe, :server, order_lines: :orderable)
                    .order(created_at: :desc)

      render json: {
        code: 200,
        success: true,
        data: orders.map { |o| order_with_images(o) },
        errors: []
      }, status: :ok
    end

    # GET /api/orders/:id — Show one order for the current user
    def show
      order = Order.includes(:table, :vibe, :server, order_lines: :orderable)
                   .find_by!(id: params[:id], client_id: current_user.id)

      render json: {
        code: 200,
        success: true,
        data: [order_with_images(order)],
        errors: []
      }, status: :ok
    end

    # POST /api/orders
    def create
      order = Order.new(order_params)
      order.client_id = current_user.id

      if order.save
        render json: { code: 200, success: true, data: [order.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: order.errors.full_messages }, status: :ok
      end
    end

    # POST /api/orders/close_open — Close all open orders for the current user
    def close_open
      Order.open.where(client_id: current_user.id).each { |o| o.update(ended_at: Time.current) }

      render json: { code: 200, success: true, data: [], errors: [] }, status: :ok
    end

    # PUT /api/orders/:id
    def update
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      if order.update(order_update_params)
        render json: { code: 200, success: true, data: [order.reload.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: order.errors.full_messages }, status: :ok
      end
    end

    # POST /api/orders/:id/pay
    def pay
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      if order.ended_at.present?
        return render json: { code: 200, success: false, data: [], errors: ["Order is already closed"] }, status: :ok
      end

      # All lines must be served before paying (uses enum query method)
      unless order.order_lines.all?(&:served?)
        return render json: { code: 200, success: false, data: [], errors: ["All items must be 'served' before paying"] }, status: :ok
      end

      tip_value = params[:tip].to_f

      if tip_value < 0
        return render json: { code: 200, success: false, data: [], errors: ["Tip cannot be negative"] }, status: :ok
      end

      if tip_value > 999.99
        return render json: { code: 200, success: false, data: [], errors: ["Tip cannot exceed 999.99"] }, status: :ok
      end

      order.tip = tip_value
      order.ended_at = Time.current

      if order.save(validate: false)
        render json: { code: 200, success: true, data: [order.reload.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: order.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/orders/:id (hard delete, dependent: :destroy handles order_lines)
    def destroy
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      order.destroy

      render json: { code: 200, success: true, data: [], errors: [] }, status: :ok
    end

    private

    def order_params
      params.require(:order).permit(:nb_people, :note, :table_id, :vibe_id, :tip)
    end

    def order_update_params
      params.require(:order).permit(:note)
    end

    # Add image_url to each order line (needs controller context for url_for)
    def order_with_images(order)
      data = order.as_json
      data[:order_lines] = order.order_lines.map do |line|
        ld = line.as_json
        ld[:image_url] = line.orderable&.respond_to?(:image) && line.orderable&.image&.attached? ? url_for(line.orderable.image) : nil
        ld
      end
      data
    end
  end
end
