module Api
  class CategoriesController < AdminController
    skip_before_action :authenticate_user!, only: [:index]
    skip_before_action :require_admin!, only: [:index]

    # GET /api/categories
    def index
      categories = Category.order(:position)

      render json: {
        success: true,
        data: categories.map { |c| category_json(c) },
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

    private

    def category_params
      params.require(:category).permit(:name, :position)
    end

    def category_json(category)
      category.as_json(only: [:id, :name, :position, :created_at])
    end
  end
end
