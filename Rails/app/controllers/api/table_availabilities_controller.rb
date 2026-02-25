class Api::TableAvailabilitiesController < Api::AdminController
  before_action :set_table
  before_action :set_availability, only: [:update, :destroy]

  def index
    render json: { success: true, data: @table.availabilities.order(:start_at).map { |a| availability_json(a) } }
  end

  def create
    availability = @table.availabilities.build(availability_params)
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

  def set_table
    @table = Table.find(params[:table_id])
  end

  def set_availability
    @availability = @table.availabilities.find(params[:id])
  end

  def availability_params
    params.require(:availability).permit(:start_at, :end_at, :description)
  end

  def availability_json(a)
    a.as_json(only: [:id, :start_at, :end_at, :description])
  end
end
