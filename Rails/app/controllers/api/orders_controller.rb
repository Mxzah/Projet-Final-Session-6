# frozen_string_literal: true

module Api
  # CRUD operations for customer orders
  class OrdersController < ApiController
    before_action :authenticate_user!
    before_action :set_order, only: %i[show update pay destroy]

    # GET /api/orders — All orders for the current user
    def index
      orders = current_user.orders_as_client
                           .includes(:table, :vibe, :server, order_lines: :orderable)

      # Search by item name, combo name, server name, vibe name, or table number
      if params[:search].present?
        term = "%#{params[:search]}%"
        matching_ids = current_user.orders_as_client
                                   .joins(
                                     "LEFT JOIN order_lines item_lines " \
                                     "ON item_lines.order_id = orders.id AND item_lines.orderable_type = 'Item'"
                                   )
                                   .joins("LEFT JOIN items ON items.id = item_lines.orderable_id")
                                   .joins(
                                     "LEFT JOIN order_lines combo_lines " \
                                     "ON combo_lines.order_id = orders.id AND combo_lines.orderable_type = 'Combo'"
                                   )
                                   .joins("LEFT JOIN combos ON combos.id = combo_lines.orderable_id")
                                   .joins("LEFT JOIN users  servers ON servers.id = orders.server_id")
                                   .joins("LEFT JOIN vibes  ON vibes.id  = orders.vibe_id")
                                   .joins("LEFT JOIN tables ON tables.id = orders.table_id")
                                   .where(
                                     "items.name ILIKE :t OR combos.name ILIKE :t OR vibes.name ILIKE :t " \
                                     "OR CAST(tables.number AS TEXT) ILIKE :t " \
                                     "OR servers.first_name ILIKE :t OR servers.last_name ILIKE :t " \
                                     "OR CONCAT(servers.first_name, ' ', servers.last_name) ILIKE :t",
                                     t: term
                                   )
                                   .distinct.pluck(:id)
        orders = orders.where(id: matching_ids)
      end

      # Filter: only closed orders (history)
      orders = orders.where.not(ended_at: nil) if params[:closed] == "true"

      # Sort
      orders = case params[:sort]
      when "oldest"
                 orders.order(created_at: :asc)
      when "total_asc"
                 orders.order(created_at: :desc) # sorted client-side for computed total
      when "total_desc"
                 orders.order(created_at: :desc) # sorted client-side for computed total
      else
                 orders.order(created_at: :desc)
      end

      render_success(data: orders.map { |o| order_with_images(o) }, errors: [])
    end

    # GET /api/orders/:id — Show one order for the current user
    def show
      render_success(data: order_with_images(@order), errors: [])
    end

    # POST /api/orders
    def create
      order = Order.new(order_params)
      order.client = current_user

      # Validate server_id is actually a Waiter if provided
      if order.server_id.present?
        waiter = User.find_by(id: order.server_id)
        order.server_id = nil unless waiter&.type == "Waiter"
      end

      if order.save
        render_success(data: order.as_json, errors: [])
      else
        render_error(order.errors.full_messages)
      end
    end

    # POST /api/orders/close_open — Close all open orders for the current user
    def close_open
      current_user.orders_as_client.open.each { |o| o.update(ended_at: Time.current) }

      render_success(data: [], errors: [])
    end

    # PUT /api/orders/:id
    def update
      if @order.update(order_update_params)
        render_success(data: @order.reload.as_json, errors: [])
      else
        render_error(@order.errors.full_messages)
      end
    end

    # POST /api/orders/:id/pay
    def pay
      return render_error(I18n.t("controllers.orders.already_closed")) if @order.ended_at.present?

      return render_error(I18n.t("controllers.orders.not_all_served")) unless @order.order_lines.all?(&:served?)

      tip_value = params[:tip].to_f

      return render_error(I18n.t("controllers.orders.tip_negative")) if tip_value.negative?

      return render_error(I18n.t("controllers.orders.tip_too_high")) if tip_value > 999.99

      @order.tip = tip_value
      @order.ended_at = Time.current

      if @order.save(validate: false)
        render_success(data: @order.reload.as_json, errors: [])
      else
        render_error(@order.errors.full_messages)
      end
    end

    # DELETE /api/orders/:id (hard delete, dependent: :destroy handles order_lines)
    def destroy
      @order.destroy
      render_success(data: [], errors: [])
    end

    private

    def order_params
      params.require(:order).permit(:nb_people, :note, :table_id, :vibe_id, :tip, :server_id)
    end

    def order_update_params
      params.require(:order).permit(:note)
    end

    def set_order
      @order = current_user.orders_as_client
                           .includes(:table, :vibe, :server, order_lines: :orderable)
                           .find_by(id: params[:id])
      render_error(I18n.t("controllers.orders.not_found")) unless @order
    end

    # Add image data (hash format) to order and each order line
    def order_with_images(order)
      data = order.as_json
      data[:vibe_image] = if order.vibe&.image&.attached?
                            blob = order.vibe.image.blob
                            {
                              url: rails_storage_proxy_path(order.vibe.image),
                              filename: blob.filename.to_s,
                              content_type: blob.content_type,
                              byte_size: blob.byte_size
                            }
      end
      data[:order_lines] = order.order_lines.map do |line|
        ld = line.as_json
        if line.orderable.respond_to?(:image) && line.orderable&.image&.attached?
          blob = line.orderable.image.blob
          ld[:image] = {
            url: rails_storage_proxy_path(line.orderable.image),
            filename: blob.filename.to_s,
            content_type: blob.content_type,
            byte_size: blob.byte_size
          }
        end
        ld
      end
      data
    end
  end
end
