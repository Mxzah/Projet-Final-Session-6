module Api
  class ComboItemsController < AdminController
    skip_before_action :require_admin!, only: [:index]

    def index
      combo_items = if params[:include_deleted] == 'true' && current_user&.is_a?(Administrator)
                      ComboItem.unscoped.includes(:combo, :item).order(combo_id: :asc, item_id: :asc)
                    else
                      ComboItem.includes(:combo, :item).order(combo_id: :asc, item_id: :asc)
                    end

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

    def destroy
      combo_item = ComboItem.find(params[:id])
      combo_item.soft_delete!

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: {
        success: false,
        data: nil,
        errors: [I18n.t('controllers.combo_items.not_found')]
      }, status: :not_found
    end

    private

    def combo_item_params
      params.require(:combo_item).permit(:combo_id, :item_id, :quantity)
    end

    def combo_item_json(combo_item)
      item = combo_item.item
      {
        id: combo_item.id,
        combo_id: combo_item.combo_id,
        combo_name: combo_item.combo&.name,
        item_id: combo_item.item_id,
        item_name: item&.name,
        item_image_url: item&.image&.attached? ? url_for(item.image) : nil,
        quantity: combo_item.quantity,
        deleted_at: combo_item.deleted_at
      }
    end
  end
end
