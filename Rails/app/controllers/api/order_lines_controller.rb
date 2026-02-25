module Api
  class OrderLinesController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders/:order_id/order_lines
    def index
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)
      lines = order.order_lines.includes(:orderable).order(created_at: :asc)

      render json: {
        code: 200,
        success: true,
        data: lines.map { |l| line_with_image(l) },
        errors: []
      }, status: :ok
    end

    # POST /api/orders/:order_id/order_lines
    def create
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)

      line = order.order_lines.build(line_params)
      line.status = "sent"

      # Assign the unit_price from the Item or Combo
      if line.orderable_type.present? && line.orderable_id.present?
        orderable = find_orderable(line.orderable_type, line.orderable_id)
        line.unit_price = orderable.price if orderable
      end

      if line.save
        render json: { code: 200, success: true, data: [line_with_image(line)], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: line.errors.full_messages }, status: :ok
      end
    end

    # PUT /api/orders/:order_id/order_lines/:id
    def update
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)
      return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok unless order

      line = order.order_lines.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok unless line

      # Only 'sent' lines can be modified (uses enum query method)
      unless line.sent?
        return render json: { code: 200, success: false, data: [], errors: ["Cannot modify line with status: #{line.status}. Only 'sent' lines can be modified."] }, status: :ok
      end

      if line.update(line_update_params)
        render json: { code: 200, success: true, data: [line_with_image(line.reload)], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: line.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/orders/:order_id/order_lines/:id (hard delete)
    def destroy
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)
      return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok unless order

      line = order.order_lines.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok unless line

      # Only 'sent' lines can be deleted (uses enum query method)
      unless line.sent?
        return render json: { code: 200, success: false, data: [], errors: ["Cannot delete line with status: #{line.status}. Only 'sent' lines can be deleted."] }, status: :ok
      end

      line.destroy
      render json: { code: 200, success: true, data: [], errors: [] }, status: :ok
    end

    private

    def line_params
      params.require(:order_line).permit(:quantity, :note, :orderable_type, :orderable_id)
    end

    def line_update_params
      params.require(:order_line).permit(:quantity, :note)
    end

    # Find the Item or Combo to assign unitprice
    def find_orderable(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end

    # Add image_url to line data (needs controller context for url_for)
    def line_with_image(line)
      data = line.as_json
      data[:image_url] = line.orderable&.respond_to?(:image) && line.orderable&.image&.attached? ? url_for(line.orderable.image) : nil
      data
    end
  end
end
