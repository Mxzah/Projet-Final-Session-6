module Api
  class OrderLinesController < ApiController
    before_action :authenticate_user!
    before_action :set_order
    before_action :set_line, only: [ :update, :destroy ]

    # GET /api/orders/:order_id/order_lines
    def index
      lines = @order.order_lines.includes(:orderable).order(created_at: :asc)

      render_success(data: lines.map { |l| line_with_image(l) }, errors: [])
    end

    # POST /api/orders/:order_id/order_lines
    def create
      line = @order.order_lines.build(line_params)

      if line.save
        render_success(data: line_with_image(line), errors: [])
      else
        render_error(line.errors.full_messages)
      end
    end

    # PUT /api/orders/:order_id/order_lines/:id
    def update
      unless @line.waiting? || @line.sent?
        return render_error(I18n.t("controllers.order_lines.cannot_modify", status: @line.status))
      end

      if @line.update(line_update_params)
        render_success(data: line_with_image(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # DELETE /api/orders/:order_id/order_lines/:id (hard delete)
    def destroy
      unless @line.waiting? || @line.sent?
        return render_error(I18n.t("controllers.order_lines.cannot_delete", status: @line.status))
      end

      if @line.destroy
        render_success(data: [], errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # POST /api/orders/:order_id/order_lines/send_lines
    # Batch update all 'waiting' lines to 'sent'
    def send_lines
      waiting_lines = @order.order_lines.waiting

      if waiting_lines.empty?
        return render_error(I18n.t("controllers.order_lines.no_waiting_lines"))
      end

      waiting_lines.update_all(status: "sent")

      render_success(data: @order.order_lines.reload.includes(:orderable).map { |l| line_with_image(l) }, errors: [])
    end

    private

    def line_params
      params.require(:order_line).permit(:quantity, :note, :orderable_type, :orderable_id)
    end

    def line_update_params
      params.require(:order_line).permit(:quantity, :note)
    end

    def set_order
      @order = current_user.orders_as_client.find_by(id: params[:order_id])
      render_error(I18n.t("controllers.order_lines.order_not_found")) unless @order
    end

    def set_line
      @line = @order.order_lines.find_by(id: params[:id])
      render_error(I18n.t("controllers.order_lines.not_found")) unless @line
    end

    # Add image data (hash format) to line
    def line_with_image(line)
      data = line.as_json
      if line.orderable&.respond_to?(:image) && line.orderable&.image&.attached?
        blob = line.orderable.image.blob
        data[:image] = {
          url:          url_for(line.orderable.image),
          filename:     blob.filename.to_s,
          content_type: blob.content_type,
          byte_size:    blob.byte_size
        }
      end
      data
    end
  end
end
