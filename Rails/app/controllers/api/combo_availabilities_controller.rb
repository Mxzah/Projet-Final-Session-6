class Api::ComboAvailabilitiesController < Api::AdminController
  before_action :set_combo
  before_action :set_availability, only: [:update, :destroy]

  def index
    render json: { success: true, data: @combo.availabilities.order(:start_at).map { |a| availability_json(a) } }
  end

  def create
    availability = @combo.availabilities.build(availability_params)
    if availability.save
      render json: { success: true, data: availability_json(availability) }
    else
      render json: { success: false, data: nil, errors: availability.errors.full_messages }
    end
  end

  def update
    if @availability.update(availability_params)
      render json: { success: true, data: availability_json(@availability) }
    else
      render json: { success: false, data: nil, errors: availability.errors.full_messages }
    end
  end

  def destroy
    @availability.destroy
    render json: { success: true, data: nil }
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

  def availability_json(a)
    { id: a.id, start_at: a.start_at, end_at: a.end_at, description: a.description }
  end
end
