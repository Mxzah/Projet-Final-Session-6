module Api
  class OrderLinesController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders/:order_id/order_lines
    def index
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)
      lines = order.order_lines.includes(:orderable).order(created_at: :asc)

      render json: {
        success: true,
        data: lines.map { |l| line_with_image(l) },
        errors: []
      }, status: :ok
    end

    # POST /api/orders/:order_id/order_lines
    def create
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)

      line = order.order_lines.build(line_params)
      line.status = "waiting"

      # Assign the unit_price from the Item or Combo
      if line.orderable_type.present? && line.orderable_id.present?
        orderable = find_orderable(line.orderable_type, line.orderable_id)
        line.unit_price = orderable.price if orderable
      end

      if line.save
        render json: { success: true, data: [ line_with_image(line) ], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: line.errors.full_messages }, status: :ok
      end
    end

    # PUT /api/orders/:order_id/order_lines/:id
    def update
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)
      return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.order_not_found")] }, status: :ok unless order

      line = order.order_lines.find_by(id: params[:id])
      return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.not_found")] }, status: :ok unless line

      # Only 'waiting' or 'sent' lines can be modified (uses enum query method)
      unless line.waiting? || line.sent?
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.cannot_modify", status: line.status)] }, status: :ok
      end

      if line.update(line_update_params)
        render json: { success: true, data: [ line_with_image(line.reload) ], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: line.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/orders/:order_id/order_lines/:id (hard delete)
    def destroy
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)
      return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.order_not_found")] }, status: :ok unless order

      line = order.order_lines.find_by(id: params[:id])
      return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.not_found")] }, status: :ok unless line

      # Only 'waiting' or 'sent' lines can be deleted
      unless line.waiting? || line.sent?
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.cannot_delete", status: line.status)] }, status: :ok
      end

      line.destroy
      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    # POST /api/orders/:order_id/order_lines/send_lines
    # Batch update all 'waiting' lines to 'sent'
    def send_lines
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)
      return render json: { success: false, data: nil, errors: [I18n.t("controllers.order_lines.order_not_found")] }, status: :ok unless order

      waiting_lines = order.order_lines.where(status: "waiting")

      if waiting_lines.empty?
        return render json: { success: false, data: nil, errors: ["No waiting lines to send"] }, status: :ok
      end

      waiting_lines.update_all(status: "sent")

      render json: {
        success: true,
        data: order.order_lines.reload.includes(:orderable).map { |l| line_with_image(l) },
        errors: []
      }, status: :ok
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
