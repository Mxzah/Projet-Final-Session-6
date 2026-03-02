class Api::ItemAvailabilitiesController < Api::AdminController
  before_action :set_item
  before_action :set_availability, only: [ :update, :destroy ]

  def index
    availabilities = @item.availabilities.order(:start_at)
    render json: { success: true, data: availabilities.as_json(only: [ :id, :start_at, :end_at, :description ]) }
  end

  def create
    availability = @item.availabilities.build(availability_params)
    if availability.save
      render json: { success: true, data: availability.as_json(only: [ :id, :start_at, :end_at, :description ]) }
    else
      render json: { success: false, data: nil, errors: availability.errors.full_messages }
    end
  end

  def update
    if @availability.update(availability_params)
      render json: { success: true, data: @availability.as_json(only: [ :id, :start_at, :end_at, :description ]) }
    else
      render json: { success: false, data: nil, errors: @availability.errors.full_messages }
    end
  end

  def destroy
    @availability.destroy
    render json: { success: true, data: nil }
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
