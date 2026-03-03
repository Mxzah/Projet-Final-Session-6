class Api::TableAvailabilitiesController < Api::AdminController
  before_action :set_table
  before_action :set_availability, only: [ :update, :destroy ]

  def index
    render_success(data: @table.availabilities.order(:start_at).as_json(only: [ :id, :start_at, :end_at, :description ]))
  end

  def create
    availability = @table.availabilities.build(availability_params)
    if availability.save
      render_success(data: availability.as_json(only: [ :id, :start_at, :end_at, :description ]))
    else
      render_error(availability.errors.full_messages)
    end
  end

  def update
    if @availability.update(availability_params)
      render_success(data: @availability.as_json(only: [ :id, :start_at, :end_at, :description ]))
    else
      render_error(@availability.errors.full_messages)
    end
  end

  def destroy
    @availability.destroy
    render_success(data: nil)
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
end
