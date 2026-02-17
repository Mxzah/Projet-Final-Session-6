module Api
  class ItemsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_item, only: [:show, :update, :destroy]

    # GET /api/items?search=…&sort=asc|desc&price_min=…&price_max=…
    def index
      items = Item.includes(:category)

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
        }, status: :created
      else
        render json: {
          success: false,
          data: nil,
          errors: item.errors.full_messages
        }, status: :unprocessable_entity
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
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/items/:id (soft delete)
    def destroy
      @item.soft_delete

      render json: {
        success: true,
        data: nil,
        errors: []
      }, status: :ok
    end

    private

    def set_item
      @item = Item.find_by(id: params[:id])
      return if @item

      render json: {
        success: false,
        data: nil,
        errors: ["Item introuvable"]
      }, status: :not_found
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
        created_at: item.created_at
      }
    end
  end
end
