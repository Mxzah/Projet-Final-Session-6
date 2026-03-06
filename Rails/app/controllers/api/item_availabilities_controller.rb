# frozen_string_literal: true

module Api
  # Manage availability windows for items
  class ItemAvailabilitiesController < Api::AdminController
    before_action :set_item
    before_action :set_availability, only: %i[update destroy]

    def index
      render_success(data: @item.availabilities.order(:start_at).as_json(only: %i[id start_at end_at description]))
    end

    def create
      availability = @item.availabilities.build(availability_params)
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

    def set_item
      @item = Item.where(id: params[:item_id]).first!
    end

    def set_availability
      @availability = @item.availabilities.find(params[:id])
    end

    def availability_params
      params.require(:availability).permit(:start_at, :end_at, :description)
    end
  end
end
