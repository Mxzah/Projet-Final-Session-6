module Api
  class CategoriesController < ApplicationController
    before_action :authenticate_user!
    before_action :set_category, only: [:show, :update, :destroy]

    # GET /api/categories
    def index
      categories = Category.order(:position)

      render json: {
        success: true,
        data: categories.map { |c| category_json(c) },
        errors: []
      }, status: :ok
    end

    # GET /api/categories/:id
    def show
      render json: {
        success: true,
        data: category_json(@category),
        errors: []
      }, status: :ok
    end

    # POST /api/categories
    def create
      category = Category.new(category_params)

      if category.save
        render json: {
          success: true,
          data: category_json(category),
          errors: []
        }, status: :created
      else
        render json: {
          success: false,
          data: nil,
          errors: category.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /api/categories/:id
    def update
      if @category.update(category_params)
        render json: {
          success: true,
          data: category_json(@category),
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: @category.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    # DELETE /api/categories/:id
    def destroy
      if @category.destroy
        render json: {
          success: true,
          data: nil,
          errors: []
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: @category.errors.full_messages
        }, status: :unprocessable_entity
      end
    end

    private

    def set_category
      @category = Category.find_by(id: params[:id])
      return if @category

      render json: {
        success: false,
        data: nil,
        errors: ["Catégorie introuvable"]
      }, status: :not_found
    end

    def category_params
      params.require(:category).permit(:name, :position)
    end

    def category_json(category)
      {
        id: category.id,
        name: category.name,
        position: category.position,
        created_at: category.created_at
      }
    end
  end
end
