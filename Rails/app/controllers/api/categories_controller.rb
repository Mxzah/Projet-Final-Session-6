module Api
  class CategoriesController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]

    # GET /api/categories
    def index
      categories = Category.includes(:availabilities).order(:position)

      render_success(data: categories.as_json, errors: [])
    end

    # POST /api/categories
    def create
      category = Category.new(category_params)
      category.position = (Category.maximum(:position) || -1) + 1

      if category.save
        render_success(data: Category.includes(:availabilities).order(:position).as_json, errors: [])
      else
        render_error(category.errors.full_messages)
      end
    end

    # PATCH /api/categories/:id
    def update
      category = Category.find(params[:id])

      if category.update(category_params)
        render_success(data: Category.includes(:availabilities).order(:position).as_json, errors: [])
      else
        render_error(category.errors.full_messages)
      end
    end

    # DELETE /api/categories/:id
    def destroy
      category = Category.find(params[:id])

      if category.destroy
        render_success(data: nil, errors: [])
      else
        render_error(category.errors.full_messages)
      end
    end

    # PATCH /api/categories/reorder
    def reorder
      ids = params.require(:ids)

      Category.transaction do
        offset = Category.maximum(:position).to_i + 1000
        ids.each_with_index do |id, index|
          Category.where(id: id).update_all(position: offset + index)
        end
        ids.each_with_index do |id, index|
          Category.where(id: id).update_all(position: index)
        end
      end

      render_success(data: Category.includes(:availabilities).order(:position).as_json, errors: [])
    end

    private

    def category_params
      params.require(:category).permit(:name)
    end
  end
end
