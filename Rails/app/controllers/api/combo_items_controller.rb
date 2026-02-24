module Api
  class ComboItemsController < AdminController
    skip_before_action :require_admin!, only: [:index]

    def index
      combo_items = ComboItem.includes(:combo, :item).order(combo_id: :asc, item_id: :asc)

      render json: {
        success: true,
        data: combo_items.map { |combo_item| combo_item_json(combo_item) },
        errors: []
      }, status: :ok
    end

    def create
      combo_item = ComboItem.new(combo_item_params)

      if combo_item.save
        combo_item = ComboItem.includes(:combo, :item).find(combo_item.id)

        render json: {
          success: true,
          data: combo_item_json(combo_item),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: combo_item.errors.full_messages
        }, status: :ok
      end
    end

    private

    def combo_item_params
      params.require(:combo_item).permit(:combo_id, :item_id, :quantity)
    end

    def combo_item_json(combo_item)
      {
        id: combo_item.id,
        combo_id: combo_item.combo_id,
        combo_name: combo_item.combo&.name,
        item_id: combo_item.item_id,
        item_name: combo_item.item&.name,
        quantity: combo_item.quantity
      }
    end
  end
end
