module Api
  class ServerController < ApiController
    before_action :authenticate_user!
    before_action :authorize_server_staff!
    before_action :set_order, only: [ :assign, :release, :clean ]
    before_action :set_line,  only: [ :serve_line, :update_line, :destroy_line ]

    # GET /api/server/tables — returns all tables with QR tokens for the server to present
    def tables
      tables = Table.includes(:availabilities).order(:number)
      render_success(data: tables.map { |t| server_table_json(t) }, errors: [])
    end

    # GET /api/server/orders — returns { unassigned: [...], mine: [...] }
    def orders
      base = Order.where(ended_at: nil)
                  .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                  .order(created_at: :asc)

      unassigned = base.where(server_id: nil)
      mine = base.where(server: current_user)

      # Also include my orders that are paid (ended_at set) but not yet "cleaned" (released)
      # i.e. orders where ended_at is set but server is current user — for the "clean" button
      # Exclude orders whose table has been cleaned AFTER the order ended (already cleaned)
      paid_mine = Order.where(server: current_user)
                       .where("ended_at > ? AND ended_at IS NOT NULL", 24.hours.ago)
                       .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                       .order(created_at: :desc)
                       .reject { |o| o.table.cleaned_at.present? && o.table.cleaned_at >= o.ended_at }

      all_orders = (unassigned + mine + paid_mine).uniq(&:id)
      all_lines = all_orders.flat_map(&:order_lines)
      item_ids  = all_lines.select { |l| l.orderable_type == "Item" }.map(&:orderable_id).uniq
      combo_ids = all_lines.select { |l| l.orderable_type == "Combo" }.map(&:orderable_id).uniq
      items_map  = Item.where(id: item_ids).index_by(&:id)
      combos_map = Combo.where(id: combo_ids).index_by(&:id)

      render_success(data: { unassigned: unassigned.map { |o| order_json(o, items_map, combos_map) }, mine: (mine + paid_mine).uniq(&:id).map { |o| order_json(o, items_map, combos_map) } }, errors: [])
    end

    # POST /api/server/orders/:id/assign — assign current user as server
    def assign
      if @order.server_id.present?
        return render_error(I18n.t("controllers.server.already_assigned"))
      end

      @order.update!(server: current_user)

      render_success(data: [], errors: [])
    end

    # POST /api/server/orders/:id/release
    # Appelé quand le serveur clique "Libérer la table" pour une commande non payée.
    # - Ferme la commande (ended_at = maintenant)
    # - Marque server_released = true pour afficher le badge "Libérée" dans /serve
    # - NE libère PAS la table : server_id est gardé, donc la table reste occupée
    # - Le client est déconnecté côté Angular car ended_at est présent
    # La table devient disponible seulement après l'appel à "clean"
    def release
      unless @order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      unless @order.ended_at.present?
        @order.update_columns(ended_at: Time.current, server_released: true)
      end

      render_success(data: [], errors: [])
    end

    # POST /api/server/orders/:id/clean
    # Appelé quand le serveur clique "Nettoyer la table" (après paiement OU après libération).
    # - Met server_id = nil : c'est ça qui libère vraiment la table et la rend disponible
    # - La commande disparaît du dashboard /serve
    # - La table redevient disponible pour un nouveau client
    def clean
      unless @order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      @order.table.mark_cleaned!

      render_success(data: [], errors: [])
    end

    # PATCH /api/server/order_lines/:id/serve — advance from ready to served (server only)
    def serve_line
      order = @line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      unless @line.status == "ready"
        return render_error(I18n.t("controllers.server.line_not_ready"))
      end

      if @line.update(status: "served")
        render_success(data: line_json(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # PATCH /api/server/order_lines/:id — update quantity/note
    def update_line
      order = @line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      if @line.update(line_update_params)
        render_success(data: line_json(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # DELETE /api/server/order_lines/:id — hard delete
    def destroy_line
      order = @line.order
      unless order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      if @line.destroy
        render_success(data: [], errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    private

    def authorize_server_staff!
      unless %w[Administrator Waiter].include?(current_user.type)
        render_error(I18n.t("controllers.server.unauthorized"))
      end
    end

    def set_order
      @order = Order.find_by(id: params[:id])
      render_error(I18n.t("controllers.server.order_not_found")) unless @order
    end

    def set_line
      @line = OrderLine.find_by(id: params[:id])
      render_error(I18n.t("controllers.server.line_not_found")) unless @line
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
        server_released: order.server_released,
        order_lines: lines
      }
    end

    def find_orderable(type, id, items_map, combos_map)
      return nil unless type.present? && id.present?
      return items_map[id]  if type == "Item"
      return combos_map[id] if type == "Combo"
      nil
    end

    def server_table_json(table)
      {
        id: table.id,
        number: table.number,
        capacity: table.nb_seats,
        status: (table.cleaned_at.nil? ? table.orders.any? : table.orders.where("created_at > ?", table.cleaned_at).any?) ? "occupied" : "available",
        qr_token: table.temporary_code,
        availabilities: table.availabilities.map { |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at }
        }
      }
    end
  end
end
