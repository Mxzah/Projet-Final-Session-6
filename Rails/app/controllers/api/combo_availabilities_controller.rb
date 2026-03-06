# frozen_string_literal: true

module Api
  # Manage availability windows for combos
  class ComboAvailabilitiesController < Api::AdminController
    before_action :set_combo
    before_action :set_availability, only: %i[update destroy]

    def index
      render_success(data: @combo.availabilities.order(:start_at).as_json(only: %i[id start_at end_at
                                                                                   description]))
    end

    def create
      availability = @combo.availabilities.build(availability_params)
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

    def set_combo
      @combo = Combo.find(params[:combo_id])
    end

    def set_availability
      @availability = @combo.availabilities.find(params[:id])
    end

    def availability_params
      params.require(:availability).permit(:start_at, :end_at, :description)
    end
  end
end
