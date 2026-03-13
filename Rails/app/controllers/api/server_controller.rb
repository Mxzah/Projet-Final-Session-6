# frozen_string_literal: true

module Api
  # Server/waiter dashboard for table and order management
  class ServerController < ApiController
    before_action :authenticate_user!
    before_action :authorize_server_staff!
    before_action :set_order, only: %i[assign release clean cancel]
    before_action :set_line,  only: %i[serve_line update_line destroy_line]

    # GET /api/server/tables — returns all tables with QR tokens for the server to present
    def tables
      now = Time.current
      occupied_ids = Table.joins(:orders).where(orders: { ended_at: nil }).distinct.pluck(:id)
      available_ids = Table.joins(:availabilities)
                          .where("availabilities.start_at <= ? AND (availabilities.end_at IS NULL OR availabilities.end_at > ?)", now, now)
                          .distinct.pluck(:id)
      table_ids = (occupied_ids + available_ids).uniq
      tables = Table.where(id: table_ids).includes(:availabilities, orders: :server).order(:number)
      render_success(data: tables.map { |t| server_table_json(t) }, errors: [])
    end

    # GET /api/server/orders — returns { mine: [...] }
    # Admin sees ALL orders; waiters see only their own.
    def orders
      base_scope = current_user.is_a?(Administrator) ? Order.all : Order.where(server: current_user)

      mine = base_scope.where(ended_at: nil)
                       .includes(:table, :client, :server, :vibe)
                       .preload(order_lines: :orderable)
                       .order(created_at: :asc)

      paid_mine = base_scope.where("ended_at > ? AND ended_at IS NOT NULL", 24.hours.ago)
                            .joins(:table)
                            .where("tables.cleaned_at IS NULL OR tables.cleaned_at < orders.ended_at")
                            .includes(:client, :server, :vibe)
                            .preload(:table, order_lines: :orderable)
                            .order(created_at: :desc)

      all_orders = (mine + paid_mine).uniq(&:id)

      render_success(data: { mine: all_orders.map { |o| order_json(o) } }, errors: [])
    end

    # POST /api/server/orders/:id/assign — assign current user as server
    def assign
      return render_error(I18n.t("controllers.server.already_assigned")) if @order.server_id.present?

      @order.update!(server: current_user)

      render_success(data: [], errors: [])
    end

    # POST /api/server/orders/:id/release
    def release
      unless @order.server_id == current_user.id || current_user.is_a?(Administrator)
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      # Block release if any order lines are not yet served
      table = @order.table
      open_orders = if current_user.is_a?(Administrator)
                      table.orders.where(ended_at: nil)
                    else
                      table.orders.where(ended_at: nil, server_id: current_user.id)
                    end
      unserved = open_orders.joins(:order_lines).where.not(order_lines: { status: "served" }).exists?
      return render_error(I18n.t("controllers.server.not_all_served")) if unserved

      # Close ALL open orders on this table
      open_orders.update_all(ended_at: Time.current, server_released: true)

      render_success(data: [], errors: [])
    end

    # POST /api/server/orders/:id/clean
    # Appelé quand le serveur clique "Nettoyer la table" (après paiement OU après libération).
    # - Ferme la commande si pas encore fermée (ended_at)
    # - Met cleaned_at sur la table + régénère le QR code
    # - La table redevient disponible pour un nouveau client
    def clean
      unless @order.server_id == current_user.id || current_user.is_a?(Administrator)
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      # Close ALL open orders on this table (multiple clients may have joined)
      table = @order.table
      table.orders.where(ended_at: nil).update_all(ended_at: Time.current, server_released: true)

      # Clean the table and regenerate QR code (once for all orders)
      table.update!(
        cleaned_at: Time.current,
        temporary_code: SecureRandom.hex(16),
        qr_rotated_at: Time.current
      )

      render_success(data: [], errors: [])
    end

    # DELETE /api/server/orders/:id/cancel — cancel an empty order (no sent lines)
    def cancel
      unless @order.server_id == current_user.id || current_user.is_a?(Administrator)
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      return render_error(I18n.t("controllers.server.order_already_closed")) if @order.ended_at.present?

      sent_lines = @order.order_lines.where.not(status: "waiting")
      if sent_lines.exists?
        return render_error(I18n.t("controllers.server.cancel_has_lines"))
      end

      # Destroy waiting lines (if any) and delete the order
      @order.order_lines.destroy_all
      @order.update!(deleted_at: Time.current)

      # Clean and release the table so it becomes available again
      table = @order.table
      remaining_open = table.orders.where(ended_at: nil, deleted_at: nil).where.not(id: @order.id)
      unless remaining_open.exists?
        table.update!(
          cleaned_at: Time.current,
          temporary_code: SecureRandom.hex(16),
          qr_rotated_at: Time.current
        )
      end

      render_success(data: [], errors: [])
    end

    # PATCH /api/server/order_lines/:id/serve — advance from ready to served (server only)
    def serve_line
      order = @line.order
      unless order.server_id == current_user.id || current_user.is_a?(Administrator)
        return render_error(I18n.t("controllers.server.not_assigned"))
      end

      return render_error(I18n.t("controllers.server.line_not_ready")) unless @line.status == "ready"

      if @line.update(status: "served")
        render_success(data: line_json(@line.reload), errors: [])
      else
        render_error(@line.errors.full_messages)
      end
    end

    # PATCH /api/server/order_lines/:id — update quantity/note
    def update_line
      order = @line.order
      unless order.server_id == current_user.id || current_user.is_a?(Administrator)
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
      unless order.server_id == current_user.id || current_user.is_a?(Administrator)
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
      return if current_user.is_a?(Administrator) || current_user.is_a?(Waiter)

      render_error(I18n.t("controllers.server.unauthorized"))
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

    def order_json(order)
      visible_lines = order.order_lines.reject { |l| l.status == "waiting" }
      lines = visible_lines.map do |l|
        {
          id: l.id,
          quantity: l.quantity,
          unit_price: l.unit_price.to_f,
          note: l.note,
          status: l.status,
          orderable_type: l.orderable_type,
          orderable_id: l.orderable_id,
          orderable_name: l.orderable&.name
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
        availabilities: table.availabilities.map do |a|
          { id: a.id, start_at: a.start_at, end_at: a.end_at }
        end
      }
    end
  end
end
