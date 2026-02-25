module Api
  class CuisineController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_kitchen_staff!

    # GET /api/kitchen/orders — All open orders with their lines
    def orders
      active_orders = Order.open
                           .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                           .order(created_at: :asc)

      render json: {
        code: 200,
        success: true,
        data: active_orders.map(&:as_json),
        errors: []
      }, status: :ok
    end

    # POST /api/kitchen/orders/:id/release (waiter/admin only — closes the order like paying)
    def release_order
      return render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok unless senior_staff?

      order = Order.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok unless order

      if order.ended_at.present?
        return render json: { code: 200, success: false, data: [], errors: ["Order is already closed"] }, status: :ok
      end

      order.ended_at = Time.current
      if order.save(validate: false)
        render json: { code: 200, success: true, data: [order.reload.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: order.errors.full_messages }, status: :ok
      end
    end

    # PUT /api/kitchen/order_lines/:id/next_status (all kitchen staff)
    def next_status
      line = OrderLine.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok unless line

      current_index = OrderLine::STATUS_ORDER[line.status]
      next_s = OrderLine::STATUSES[current_index + 1]

      unless next_s
        return render json: { code: 200, success: false, data: [], errors: ["Already at final status"] }, status: :ok
      end

      if line.update(status: next_s)
        render json: { code: 200, success: true, data: [line.reload.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: line.errors.full_messages }, status: :ok
      end
    end

    # PUT /api/kitchen/order_lines/:id (waiter/admin only — quantity and note)
    def update_line
      return render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok unless senior_staff?

      line = OrderLine.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok unless line

      # Only 'sent' lines can be modified (uses enum query method)
      unless line.sent?
        return render json: { code: 200, success: false, data: [], errors: ["Cannot modify line with status '#{line.status}'. Only 'sent' lines can be modified."] }, status: :ok
      end

      if line.update(line_update_params)
        render json: { code: 200, success: true, data: [line.reload.as_json], errors: [] }, status: :ok
      else
        render json: { code: 200, success: false, data: [], errors: line.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/kitchen/order_lines/:id (waiter/admin only — hard delete, status must be 'sent')
    def destroy_line
      return render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok unless senior_staff?

      line = OrderLine.find_by(id: params[:id])
      return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok unless line

      # Only 'sent' lines can be deleted (uses enum query method)
      unless line.sent?
        return render json: { code: 200, success: false, data: [], errors: ["Cannot delete line with status '#{line.status}'. Only 'sent' lines can be deleted."] }, status: :ok
      end

      line.destroy
      render json: { code: 200, success: true, data: [], errors: [] }, status: :ok
    end

    private

    def authorize_kitchen_staff!
      unless %w[Administrator Waiter Cook].include?(current_user.type)
        render json: { code: 200, success: false, data: [], errors: ["Unauthorized"] }, status: :ok
      end
    end

    def senior_staff?
      %w[Administrator Waiter].include?(current_user.type)
    end

    def line_update_params
      params.require(:order_line).permit(:quantity, :note)
    end
  end
end
