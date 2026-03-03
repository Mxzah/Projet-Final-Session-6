module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders — All orders for the current user
    def index
      orders = Order.where(client_id: current_user.id)
                    .includes(:table, :vibe, :server, order_lines: :orderable)

      # Search by item name, combo name, server name, vibe name, or table number
      if params[:search].present?
        term = "%#{params[:search]}%"
        item_order_ids = OrderLine.joins(:order)
                             .where(orders: { client_id: current_user.id })
                             .joins("INNER JOIN items ON items.id = order_lines.orderable_id AND order_lines.orderable_type = 'Item'")
                             .where("items.name ILIKE ?", term)
                             .select(:order_id).distinct
        combo_order_ids = OrderLine.joins(:order)
                             .where(orders: { client_id: current_user.id })
                             .joins("INNER JOIN combos ON combos.id = order_lines.orderable_id AND order_lines.orderable_type = 'Combo'")
                             .where("combos.name ILIKE ?", term)
                             .select(:order_id).distinct
        server_order_ids = Order.where(client_id: current_user.id)
                          .joins("INNER JOIN users ON users.id = orders.server_id")
                          .where("users.first_name ILIKE :t OR users.last_name ILIKE :t OR CONCAT(users.first_name, ' ', users.last_name) ILIKE :t", t: term)
                          .select(:id).distinct
        vibe_order_ids = Order.where(client_id: current_user.id)
                          .joins(:vibe)
                          .where("vibes.name ILIKE ?", term)
                          .select(:id).distinct
        table_order_ids = Order.where(client_id: current_user.id)
                          .joins(:table)
                          .where("CAST(tables.number AS TEXT) ILIKE ?", term)
                          .select(:id).distinct
        all_matching_ids = [item_order_ids, combo_order_ids, server_order_ids, vibe_order_ids, table_order_ids].map { |rel| rel.pluck(:id).presence || [] }.flatten.uniq
        orders = orders.where(id: all_matching_ids)
      end

      # Filter: only closed orders (history)
      orders = orders.where.not(ended_at: nil) if params[:closed] == "true"

      # Sort
      case params[:sort]
      when "oldest"
        orders = orders.order(created_at: :asc)
      when "total_asc"
        orders = orders.order(created_at: :desc) # sorted client-side for computed total
      when "total_desc"
        orders = orders.order(created_at: :desc) # sorted client-side for computed total
      else
        orders = orders.order(created_at: :desc)
      end

      render json: {
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
        success: true,
        data: [ order_with_images(order) ],
        errors: []
      }, status: :ok
    end

    # POST /api/orders
    def create
      order = Order.new(order_params)
      order.client_id = current_user.id

      if order.save
        render json: { success: true, data: [ order.as_json ], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: order.errors.full_messages }, status: :ok
      end
    end

    # POST /api/orders/close_open — Close all open orders for the current user
    def close_open
      Order.open.where(client_id: current_user.id).each { |o| o.update(ended_at: Time.current) }

      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    # PUT /api/orders/:id
    def update
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.not_found")] }, status: :ok
      end

      if order.update(order_update_params)
        render json: { success: true, data: [ order.reload.as_json ], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: order.errors.full_messages }, status: :ok
      end
    end

    # POST /api/orders/:id/pay
    def pay
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.not_found")] }, status: :ok
      end

      if order.ended_at.present?
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.already_closed")] }, status: :ok
      end

      # All lines must be served before paying (uses enum query method)
      unless order.order_lines.all?(&:served?)
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.not_all_served")] }, status: :ok
      end

      tip_value = params[:tip].to_f

      if tip_value < 0
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.tip_negative")] }, status: :ok
      end

      if tip_value > 999.99
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.tip_too_high")] }, status: :ok
      end

      order.tip = tip_value
      order.ended_at = Time.current

      if order.save(validate: false) #ici le false
        render json: { success: true, data: [ order.reload.as_json ], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: order.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/orders/:id (hard delete, dependent: :destroy handles order_lines)
    def destroy
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.orders.not_found")] }, status: :ok
      end

      order.destroy

      render json: { success: true, data: [], errors: [] }, status: :ok
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
      data[:vibe_image_url] = order.vibe&.image&.attached? ? url_for(order.vibe.image) : nil
      data[:order_lines] = order.order_lines.map do |line|
        ld = line.as_json
        ld[:image_url] = line.orderable&.respond_to?(:image) && line.orderable&.image&.attached? ? url_for(line.orderable.image) : nil
        ld
      end
      data
    end
  end
end
