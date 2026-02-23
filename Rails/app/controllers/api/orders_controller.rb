module Api
  class OrdersController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders    Retourne toutes les commandes de l'utilisateur connecté.
    def index
      orders = Order.where(client_id: current_user.id)
                    .includes(:table, :order_lines, :vibe, :server)
                    .order(created_at: :desc)

      render json: {
        success: true,
        data: orders.map { |o| order_json(o) },
        error: [],
        errors: []
      }, status: :ok
    end

    # GET /api/orders/:id    Retourne les détails d'une commande spécifique de l'utilisateur connecté.
    def show
      order = Order.includes(:table, :order_lines, :vibe, :server).find_by!(id: params[:id], client_id: current_user.id)

      render json: {
        success: true,
        data: [order_json(order)],
        error: [],
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
          data: [order_json(order)],
          error: [],
          errors: []
        }, status: :ok
      else
        full_errors = order.errors.full_messages

        render json: {
          success: false,
          data: [],
          error: full_errors,
          errors: full_errors
        }, status: :ok
      end
    end

    # Ferme toutes les commandes ouvertes de l'utilisateur
    def close_open
      open_orders = Order.where(client_id: current_user.id, ended_at: nil)
      open_orders.each { |o| o.update(ended_at: Time.current) }

      render json: {
        success: true,
        data: [],
        error: [],
        errors: []
      }, status: :ok
    end

    # PUT /api/orders/:id
    def update
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: [], error: ["Order not found"], errors: ["Order not found"] }, status: :ok
      end

      if order.update(order_update_params)
        render json: {
          success: true,
          data: [order_json(order.reload)],
          error: [],
          errors: []
        }, status: :ok
      else
        full_errors = order.errors.full_messages
        render json: {
          success: false,
          data: [],
          error: full_errors,
          errors: full_errors
        }, status: :ok
      end
    end

    # DELETE /api/orders/:id  (hard delete)
    def destroy
      order = Order.find_by(id: params[:id], client_id: current_user.id)

      unless order
        return render json: { success: false, data: [], error: ["Order not found"], errors: ["Order not found"] }, status: :ok
      end

      order.order_lines.destroy_all
      order.destroy

      render json: {
        success: true,
        data: [],
        error: [],
        errors: []
      }, status: :ok
    end

    private
    #Filtre les paramètres
    def order_params
      params.require(:order).permit(:nb_people, :note, :table_id, :vibe_id, :tip)
    end

    def order_update_params
      params.require(:order).permit(:note)
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
          orderable_name: orderable&.name,
          orderable_description: orderable&.try(:description),
          image_url: orderable&.respond_to?(:image) && orderable.image.attached? ? url_for(orderable.image) : nil
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
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : nil,
        vibe_id: order.vibe_id,
        vibe_name: order.vibe&.name,
        vibe_color: order.vibe&.color,
        created_at: order.created_at,
        ended_at: order.ended_at,
        order_lines: lines,
        total: total
      }
    end
    #trouve le Item ou Combo
    def find_orderable(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end
  end
end
