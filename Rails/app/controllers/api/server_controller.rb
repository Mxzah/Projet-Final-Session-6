module Api
  class ServerController < ApiController
    before_action :authenticate_user!
    before_action :authorize_server_staff!
    before_action :set_order, only: [ :assign, :release, :clean ]
    before_action :set_line,  only: [ :serve_line, :update_line, :destroy_line ]

    # GET /api/server/tables — returns all tables with QR tokens for the server to present
    def tables
      tables = Table.includes(:availabilities, orders: :server).order(:number)
      render_success(data: tables.map { |t| server_table_json(t) }, errors: [])
    end

    # GET /api/server/orders — returns { mine: [...] }
    def orders
      mine = Order.where(ended_at: nil, server: current_user)
                  .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                  .order(created_at: :asc)

      # Also include my orders that are paid (ended_at set) but not yet "cleaned"
      # Exclude orders whose table has been cleaned AFTER the order ended (already cleaned)
      paid_mine = Order.where(server: current_user)
                       .where("ended_at > ? AND ended_at IS NOT NULL", 24.hours.ago)
                       .includes(:table, :client, :server, :vibe, order_lines: :orderable)
                       .order(created_at: :desc)
                       .reject { |o| o.table.cleaned_at.present? && o.table.cleaned_at >= o.ended_at }

      all_orders = (mine + paid_mine).uniq(&:id)
      all_lines = all_orders.flat_map(&:order_lines)
      item_ids  = all_lines.select { |l| l.orderable_type == "Item" }.map(&:orderable_id).uniq
      combo_ids = all_lines.select { |l| l.orderable_type == "Combo" }.map(&:orderable_id).uniq
      items_map  = Item.where(id: item_ids).index_by(&:id)
      combos_map = Combo.where(id: combo_ids).index_by(&:id)

      render_success(data: { mine: all_orders.map { |o| order_json(o, items_map, combos_map) } }, errors: [])
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
    def release
      unless @order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      # Close ALL open orders on this table for this server (multiple clients may have joined)
      table = @order.table
      table.orders.where(ended_at: nil, server_id: current_user.id).update_all(ended_at: Time.current, server_released: true)

      render_success(data: [], errors: [])
    end

    # POST /api/server/orders/:id/clean
    # Appelé quand le serveur clique "Nettoyer la table" (après paiement OU après libération).
    # - Ferme la commande si pas encore fermée (ended_at)
    # - Met cleaned_at sur la table + régénère le QR code
    # - La table redevient disponible pour un nouveau client
    def clean
      unless @order.server_id == current_user.id || current_user.type == "Administrator"
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      # Close ALL open orders on this table (multiple clients may have joined)
      table = @order.table
      table.orders.where(ended_at: nil).update_all(ended_at: Time.current)

      # Clean the table and regenerate QR code (once for all orders)
      table.update!(
        cleaned_at: Time.current,
        temporary_code: SecureRandom.hex(16),
        qr_rotated_at: Time.current
      )

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

      if @line.status == "served"
        return render_error(I18n.t("controllers.server.cannot_modify_line", status: @line.status))
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

      unless %w[sent in_preparation].include?(@line.status)
        return render_error(I18n.t("controllers.server.cannot_delete_line", status: @line.status))
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
      open_order = table.orders.detect { |o| o.ended_at.nil? }
      server = open_order&.server
      {
        id: table.id,
        number: table.number,
        capacity: table.nb_seats,
        status: open_order ? "occupied" : "available",
        qr_token: table.temporary_code,
        server_name: server ? "#{server.first_name} #{server.last_name}" : nil,
        availabilities: table.availabilities.map { |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at }
        }
      }
    end
  end
end
