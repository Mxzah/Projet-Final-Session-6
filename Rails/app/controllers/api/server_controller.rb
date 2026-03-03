module Api
  class ServerController < ApplicationController
    before_action :authenticate_user!
    before_action :authorize_server_staff!

    # GET /api/server/orders — returns { unassigned: [...], mine: [...] }
    def orders
      base = Order.where(ended_at: nil)
                  .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                  .order(created_at: :asc)

      unassigned = base.where(server_id: nil)
      mine = base.where(server_id: current_user.id)

      # Also include my orders that are paid (ended_at set) but not yet "cleaned" (released)
      # i.e. orders where ended_at is set but server is current user — for the "clean" button
      paid_mine = Order.where.not(ended_at: nil)
                       .where(server_id: current_user.id)
                       .where("ended_at > ?", 24.hours.ago)
                       .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                       .order(created_at: :desc)

      all_orders = (unassigned + mine + paid_mine).uniq(&:id)
      all_lines = all_orders.flat_map(&:order_lines)
      item_ids  = all_lines.select { |l| l.orderable_type == "Item" }.map(&:orderable_id).uniq
      combo_ids = all_lines.select { |l| l.orderable_type == "Combo" }.map(&:orderable_id).uniq
      items_map  = Item.where(id: item_ids).index_by(&:id)
      combos_map = Combo.where(id: combo_ids).index_by(&:id)

      render json: {
        success: true,
        data: {
          unassigned: unassigned.map { |o| order_json(o, items_map, combos_map) },
          mine: (mine + paid_mine).uniq(&:id).map { |o| order_json(o, items_map, combos_map) }
        },
        errors: []
      }, status: :ok
    end

    # POST /api/server/orders/:id/assign — assign current user as server
    def assign
      order = Order.find_by(id: params[:id])

      unless order
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.order_line_not_found")] }, status: :ok
      end

      if order.server_id.present?
        return render json: { success: false, data: nil, errors: ["Un serveur est déjà assigné à cette commande"] }, status: :ok
      end

      order.update!(server_id: current_user.id)

      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    # POST /api/server/orders/:id/release — close order and free table
    def release
      order = Order.find_by(id: params[:id])

      unless order
        return render json: { success: false, data: nil, errors: ["Commande introuvable"] }, status: :ok
      end

      # Must be assigned to current user
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render json: { success: false, data: nil, errors: ["Vous n'êtes pas assigné à cette commande"] }, status: :ok
      end

      order.update_columns(ended_at: Time.current) unless order.ended_at.present?
      # NOTE: server_id is intentionally kept so it appears in the client's order history

      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    # POST /api/server/orders/:id/clean — called after payment, removes from dashboard
    def clean
      order = Order.find_by(id: params[:id])

      unless order
        return render json: { success: false, data: nil, errors: ["Commande introuvable"] }, status: :ok
      end

      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render json: { success: false, data: nil, errors: ["Vous n'êtes pas assigné à cette commande"] }, status: :ok
      end

      order.update_columns(server_id: nil)

      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    # PATCH /api/server/order_lines/:id/serve — advance from ready to served (server only)
    def serve_line
      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.order_line_not_found")] }, status: :ok
      end

      order = line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.unauthorized")] }, status: :ok
      end

      unless line.status == "ready"
        return render json: { success: false, data: nil, errors: ["Seul un plat prêt peut être marqué comme servi"] }, status: :ok
      end

      if line.update(status: "served")
        render json: { success: true, data: [line_json(line.reload)], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: line.errors.full_messages }, status: :ok
      end
    end

    # PATCH /api/server/order_lines/:id — update quantity/note
    def update_line
      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.order_line_not_found")] }, status: :ok
      end

      # Must be the assigned server or admin
      order = line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.unauthorized")] }, status: :ok
      end

      if line.status == "served"
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.cannot_modify_line", status: line.status)] }, status: :ok
      end

      if line.update(line_update_params)
        render json: { success: true, data: [line_json(line.reload)], errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: line.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/server/order_lines/:id — hard delete
    def destroy_line
      line = OrderLine.find_by(id: params[:id])

      unless line
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.order_line_not_found")] }, status: :ok
      end

      order = line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.unauthorized")] }, status: :ok
      end

      unless %w[sent in_preparation].include?(line.status)
        return render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.cannot_delete_line", status: line.status)] }, status: :ok
      end

      line.destroy
      render json: { success: true, data: [], errors: [] }, status: :ok
    end

    private

    def authorize_server_staff!
      unless %w[Administrator Waiter].include?(current_user.type)
        render json: { success: false, data: nil, errors: [I18n.t("controllers.cuisine.unauthorized")] }, status: :ok
      end
    end

    def line_update_params
      params.require(:order_line).permit(:quantity, :note)
    end

    def line_json(line)
      orderable = line.orderable
      {
        id: line.id,
        quantity: line.quantity,
        unit_price: line.unit_price.to_f,
        note: line.note,
        status: line.status,
        orderable_type: line.orderable_type,
        orderable_id: line.orderable_id,
        orderable_name: orderable&.name
      }
    end

    def order_json(order, items_map, combos_map)
      visible_lines = order.order_lines.reject { |l| l.status == "waiting" }
      lines = visible_lines.map do |l|
        orderable = find_orderable(l.orderable_type, l.orderable_id, items_map, combos_map)
        {
          id: l.id,
          quantity: l.quantity,
          unit_price: l.unit_price.to_f,
          note: l.note,
          status: l.status,
          orderable_type: l.orderable_type,
          orderable_id: l.orderable_id,
          orderable_name: orderable&.name
        }
      end

      {
        id: order.id,
        nb_people: order.nb_people,
        note: order.note,
        tip: order.tip.to_f,
        vibe_name: order.vibe&.name,
        vibe_color: order.vibe&.color,
        table_number: order.table&.number,
        table_id: order.table_id,
        server_id: order.server_id,
        server_name: order.server ? "#{order.server.first_name} #{order.server.last_name}" : nil,
        created_at: order.created_at,
        ended_at: order.ended_at,
        order_lines: lines
      }
    end

    def find_orderable(type, id, items_map, combos_map)
      return nil unless type.present? && id.present?
      return items_map[id]  if type == "Item"
      return combos_map[id] if type == "Combo"
      nil
    end
  end
end
