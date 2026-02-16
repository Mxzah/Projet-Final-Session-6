module Api
  class OrderLinesController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders/:order_id/order_lines
    def index
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      lines = order.order_lines.order(created_at: :asc)

      render json: {
        success: true,
        data: lines.map { |l| line_json(l) },
        errors: []
      }, status: :ok
    end

    # POST /api/orders/:order_id/order_lines
    def create
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: line_params.to_h, errors: ["Order not found"] }, status: :ok
      end

      line = order.order_lines.build(line_params)
      line.status = "sent"

      # Set unit_price from the orderable
      orderable = find_orderable(line.orderable_type, line.orderable_id)
      if orderable
        line.unit_price = orderable.price
      end

      if line.save
        render json: {
          success: true,
          data: line_json(line),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: line.errors.full_messages
        }, status: :ok
      end
    end

    private

    def line_params
      params.require(:order_line).permit(:quantity, :note, :orderable_type, :orderable_id)
    end

    def find_orderable(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end

    def line_json(line)
      orderable = find_orderable(line.orderable_type, line.orderable_id)
      {
        id: line.id,
        quantity: line.quantity,
        unit_price: line.unit_price.to_f,
        note: line.note,
        status: line.status,
        orderable_type: line.orderable_type,
        orderable_id: line.orderable_id,
        orderable_name: orderable&.name,
        orderable_description: orderable&.try(:description),
        created_at: line.created_at
      }
    end
  end
end
