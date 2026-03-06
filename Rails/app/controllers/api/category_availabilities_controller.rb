# frozen_string_literal: true

module Api
  # Manage availability windows for categories
  class CategoryAvailabilitiesController < Api::AdminController
    before_action :set_category
    before_action :set_availability, only: %i[update destroy]

    def index
      render_success(data: @category.availabilities.order(:start_at).as_json(only: %i[id start_at end_at
                                                                                      description]))
    end

    def create
      availability = @category.availabilities.build(availability_params)
      if availability.save
        render_success(data: availability.as_json(only: %i[id start_at end_at description]))
      else
        render_error(availability.errors.full_messages)
      end
    end

    def update
      if @availability.update(availability_params)
        render_success(data: @availability.as_json(only: %i[id start_at end_at description]))
      else
        render_error(@availability.errors.full_messages)
      end
    end

    def destroy
      @availability.destroy
      render_success(data: nil)
    end

    private

    def set_category
      @category = Category.find(params[:category_id])
    end

    def set_availability
      @availability = @category.availabilities.find(params[:id])
    end

    def availability_params
      params.require(:availability).permit(:start_at, :end_at, :description)
    end
  end
end
