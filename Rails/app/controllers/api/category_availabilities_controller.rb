class Api::CategoryAvailabilitiesController < Api::AdminController
  before_action :set_category
  before_action :set_availability, only: [:update, :destroy]

  def index
    availabilities = @category.availabilities.order(:start_at)
    render json: { success: true, data: availabilities.map { |a| availability_json(a) } }
  end

  def create
    availability = @category.availabilities.build(availability_params)
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
      render json: { success: false, data: nil, errors: @availability.errors.full_messages }
    end
  end

  def destroy
    @availability.destroy
    render json: { success: true, data: nil }
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

  def availability_json(a)
    a.as_json(only: [:id, :start_at, :end_at, :description])
  end
end
