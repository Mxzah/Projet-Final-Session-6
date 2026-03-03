module Api
  class ItemsController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index, :show ]
    before_action :set_item, only: [ :show, :destroy, :hard_destroy ]
    before_action :set_item_unscoped, only: [ :update, :restore ]
    before_action :reject_if_archived, only: [ :update ]

    # GET /api/items?search=…&sort=asc|desc&price_min=…&price_max=…
    def index
      base = current_user&.type == "Administrator" ? Item.unscoped : Item
      items = base.includes(:category, :order_lines, :combo_items, :availabilities)

      unless current_user&.type == "Administrator" && params[:admin] == "true"
        now = Time.current
        items = items.joins(:availabilities)
                     .where(
                       "availabilities.start_at <= ? AND (availabilities.end_at IS NULL OR availabilities.end_at > ?)",
                       now, now
                     )
                     .distinct
      end

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
        items = items.joins(:category).order("categories.position ASC, items.name ASC")
      end

      render_success(data: items.map { |i| item_json(i) }, errors: [])
    end

    # GET /api/items/:id
    def show
      render_success(data: item_json(@item), errors: [])
    end

    # POST /api/items
    def create
      item = Item.new(item_params)

      if item.save
        render_success(data: item_json(item), errors: [])
      else
        render_error(item.errors.full_messages)
      end
    end

    # PATCH/PUT /api/items/:id
    def update
      if @item.update(item_params)
        render_success(data: item_json(@item), errors: [])
      else
        render_error(@item.errors.full_messages)
      end
    end

    # DELETE /api/items/:id (soft delete)
    def destroy
      archived_item = @item.soft_delete!

      render_success(data: item_json(archived_item), errors: [])
    end

    # DELETE /api/items/:id/hard (hard delete)
    def hard_destroy
      if @item.order_lines.any? || @item.combo_items.any?
        render_error(I18n.t("controllers.items.cannot_hard_delete"))
        return
      end

      item_data = item_json(@item)
      @item.destroy

      render_success(data: item_data, errors: [])
    end

    # PATCH /api/items/:id/restore
    def restore
      @item.update(deleted_at: nil)

      render_success(data: item_json(@item), errors: [])
    end

    private

    def set_item
      @item = Item.where(id: params[:id]).first!
    end

    def reject_if_archived
      if @item.deleted_at.present?
        render_error(I18n.t("controllers.items.cannot_update_archived"))
      end
    end

    def set_item_unscoped
      @item = Item.unscoped.find(params[:id])
    end

    def item_params
      params.require(:item).permit(:name, :description, :price, :category_id, :image)
    end

    def item_json(item)
      item.as_json(
        only: [ :id, :name, :description, :price, :category_id, :deleted_at, :created_at ],
        methods: [ :category_name, :image_url, :in_use ],
        include: { availabilities: { only: [ :id, :start_at, :end_at, :description ] } }
      )
    end
  end
end
