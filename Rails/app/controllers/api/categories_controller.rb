module Api
  class CategoriesController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]

    # GET /api/categories
    def index
      categories = Category.order(:position)

      render_success(data: categories.map { |c| category_json(c) }, errors: [])
    end

    # POST /api/categories
    def create
      category = Category.new(category_params)

      if category.save
        render_success(data: category_json(category), errors: [])
      else
        render_error(category.errors.full_messages)
      end
    end

    private

    def category_params
      params.require(:category).permit(:name, :position)
    end

    def category_json(category)
      category.as_json(only: [ :id, :name, :position, :created_at ])
    end
  end
end
