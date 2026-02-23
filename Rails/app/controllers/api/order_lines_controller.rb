module Api
  class OrderLinesController < ApplicationController
    before_action :authenticate_user!

    # GET /api/orders/:order_id/order_lines
    def index
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)

      lines = order.order_lines.order(created_at: :asc)

      render json: {
        code: 200,
        success: true,
        data: lines.map { |l| line_json(l) },
        errors: []
      }, status: :ok
    end

    # POST /api/orders/:order_id/order_lines
    def create
      order = Order.find_by!(id: params[:order_id], client_id: current_user.id)

      line = order.order_lines.build(line_params)
      line.status = "sent"

       # Va chercher le Item ou Combo
      orderable = find_orderable(line.orderable_type, line.orderable_id)
      if orderable
        line.unit_price = orderable.price
      end

      if line.save
        render json: {
          code: 200,
          success: true,
          data: [line_json(line)],
          errors: []
        }, status: :ok
      else
        full_errors = line.errors.full_messages

        render json: {
          code: 200,
          success: false,
          data: [],
          errors: full_errors
        }, status: :ok
      end
    end

    # PUT /api/orders/:order_id/order_lines/:id
    def update
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)

      unless order
        return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      line = order.order_lines.find_by(id: params[:id])

      unless line
        return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok
      end

      unless %w[sent].include?(line.status)
        return render json: { code: 200, success: false, data: [], errors: ["Cannot modify line with status: #{line.status}"] }, status: :ok
      end

      if line.update(line_update_params)
        render json: {
          code: 200,
          success: true,
          data: [line_json(line.reload)],
          errors: []
        }, status: :ok
      else
        full_errors = line.errors.full_messages
        render json: {
          code: 200,
          success: false,
          data: [],
          errors: full_errors
        }, status: :ok
      end
    end

    # DELETE /api/orders/:order_id/order_lines/:id  (hard delete)
    def destroy
      order = Order.find_by(id: params[:order_id], client_id: current_user.id)

      unless order
        return render json: { code: 200, success: false, data: [], errors: ["Order not found"] }, status: :ok
      end

      line = order.order_lines.find_by(id: params[:id])

      unless line
        return render json: { code: 200, success: false, data: [], errors: ["Order line not found"] }, status: :ok
      end

      unless %w[sent].include?(line.status)
        return render json: { code: 200, success: false, data: [], errors: ["Cannot delete line with status: #{line.status}"] }, status: :ok
      end

      line.destroy

      render json: {
        code: 200,
        success: true,
        data: [],
        errors: []
      }, status: :ok
    end

    private
    #Filtre les paramètres autorisés venant du body de la requête. Seuls quantity, note, orderable_type, et orderable_id sont acceptés
    def line_params
      params.require(:order_line).permit(:quantity, :note, :orderable_type, :orderable_id)
    end

    def line_update_params
      params.require(:order_line).permit(:quantity, :note)
    end

    # Va chercher le Item ou Combo pour assigner le prix unitaire
    def find_orderable(type, id)
      return nil unless type.present? && id.present?
      return nil unless %w[Item Combo].include?(type)
      type.constantize.find_by(id: id)
    end

    def line_json(line)
      orderable = find_orderable(line.orderable_type, line.orderable_id)
      {
        id: line.id,
        quantity: line.quantity,
        unit_price: line.unit_price.to_f,
        note: line.note,
        status: line.status,
        orderable_type: line.orderable_type, #Le type de l'objet commandé (Item ou Combo)
        orderable_id: line.orderable_id, #L'id de cet objet dans sa table.
        orderable_name: orderable&.name,  #Le nom
        orderable_description: orderable&.try(:description),     # la description
        image_url: orderable&.respond_to?(:image) && orderable.image.attached? ? url_for(orderable.image) : nil,
        created_at: line.created_at
      }
    end
  end
end
