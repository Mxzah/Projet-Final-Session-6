module Api
  class ItemsController < AdminController
    skip_before_action :authenticate_user!, only: [:index]
    skip_before_action :require_admin!, only: [:index, :show]
    before_action :set_item, only: [:show, :destroy, :hard_destroy]
    before_action :set_item_unscoped, only: [:update, :restore]
    before_action :reject_if_archived, only: [:update]

    # GET /api/items?search=…&sort=asc|desc&price_min=…&price_max=…
    def index
      base = current_user&.type == "Administrator" ? Item.unscoped : Item
      items = base.includes(:category, :order_lines, :combo_items)

      # Search
      if params[:search].present?
        items = items.where("items.name LIKE ?", "%#{params[:search]}%")
      end

      # Filter
      if params[:price_min].present?
        items = items.where("items.price >= ?", params[:price_min].to_f)
      end
      if params[:price_max].present?
        items = items.where("items.price <= ?", params[:price_max].to_f)
      end

      # Sort
      case params[:sort]
      when "asc"
        items = items.order(price: :asc)
      when "desc"
        items = items.order(price: :desc)
      else
        items = items.order(:category_id, :name)
      end

      render json: {
        success: true,
        data: items.map { |i| item_json(i) },
        errors: []
      }, status: :ok
    end

    # GET /api/items/:id
    def show
      render json: {
        success: true,
        data: item_json(@item),
        errors: []
      }, status: :ok
    end

    # POST /api/items
    def create
      item = Item.new(item_params)

      if item.save
        render json: {
          success: true,
          data: item_json(item),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: item.errors.full_messages
        }, status: :ok
      end
    end

    # PATCH/PUT /api/items/:id
    def update
      if @item.update(item_params)
        render json: {
          success: true,
          data: item_json(@item),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: @item.errors.full_messages
        }, status: :ok
      end
    end

    # DELETE /api/items/:id (soft delete)
    def destroy
      archived_item = @item.soft_delete

      render json: {
        success: true,
        data: item_json(archived_item),
        errors: []
      }, status: :ok
    end

    # DELETE /api/items/:id/hard (hard delete)
    def hard_destroy
      if @item.order_lines.any? || @item.combo_items.any?
        render json: {
          success: false,
          data: nil,
          errors: ["Cannot permanently delete an item that is used in orders or combos"]
        }, status: :ok
        return
      end

      item_data = item_json(@item)
      @item.destroy

      render json: {
        success: true,
        data: item_data,
        errors: []
      }, status: :ok
    end

    # PATCH /api/items/:id/restore
    def restore
      @item.update(deleted_at: nil)

      render json: {
        success: true,
        data: item_json(@item),
        errors: []
      }, status: :ok
    end

    private

    def set_item
      @item = Item.find(params[:id])
    end

    def reject_if_archived
      if @item.deleted_at.present?
        render json: {
          success: false,
          data: nil,
          errors: ["Cannot update an archived item"]
        }, status: :ok
      end
    end

    def set_item_unscoped
      @item = Item.unscoped.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:name, :description, :price, :category_id, :image)
    end

    def item_json(item)
      {
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price.to_f,
        category_id: item.category_id,
        category_name: item.category&.name,
        image_url: item.image.attached? ? url_for(item.image) : nil,
        deleted_at: item.deleted_at,
        created_at: item.created_at,
        in_use: item.order_lines.any? || item.combo_items.any?
      }
    end
  end
end
