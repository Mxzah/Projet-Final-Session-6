module Api
  class ComboItemsController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]
    before_action :set_combo_item, only: [ :destroy ]

    def index
      combo_items = if params[:include_deleted] == "true" && current_user&.type == "Administrator"
                      ComboItem.unscoped.includes(:combo, :item).order(combo_id: :asc, item_id: :asc)
      else
                      ComboItem.includes(:combo, :item).order(combo_id: :asc, item_id: :asc)
      end

      render_success(data: combo_items.map(&:as_json), errors: [])
    end

    def create
      combo_item = ComboItem.new(combo_item_params)

      if combo_item.save
        combo_item = ComboItem.includes(:combo, :item).find(combo_item.id)
        render_success(data: combo_item.as_json, errors: [])
      else
        render_error(combo_item.errors.full_messages)
      end
    end

    def destroy
      @combo_item.soft_delete!
      render_success(data: nil, errors: [])
    end

    private

    def set_combo_item
      @combo_item = ComboItem.find(params[:id])
    end

    def combo_item_params
      params.require(:combo_item).permit(:combo_id, :item_id, :quantity)
    end
  end
end
