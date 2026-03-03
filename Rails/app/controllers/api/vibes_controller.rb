module Api
  class VibesController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]
    before_action :set_vibe, only: [ :update, :destroy ]

    # GET /api/vibes
    def index
      base = current_user&.type == "Administrator" ? Vibe.unscoped.order(name: :asc) : Vibe.all.order(name: :asc)
      render json: {
        success: true,
        data: base.map { |v| vibe_json(v) },
        errors: []
      }, status: :ok
    end

    # POST /api/vibes
    def create
      vibe = Vibe.new(vibe_params)
      if vibe.save
        render json: { success: true, data: vibe_json(vibe), errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: vibe.errors.full_messages }, status: :ok
      end
    end

    # PUT /api/vibes/:id
    def update
      if @vibe.update(vibe_params)
        render json: { success: true, data: vibe_json(@vibe), errors: [] }, status: :ok
      else
        render json: { success: false, data: nil, errors: @vibe.errors.full_messages }, status: :ok
      end
    end

    # DELETE /api/vibes/:id
    def destroy
      if @vibe.orders.any?
        @vibe.soft_delete!
        render json: { success: true, data: vibe_json(@vibe), errors: [] }, status: :ok
      else
        data = vibe_json(@vibe)
        @vibe.destroy
        render json: { success: true, data: data, errors: [] }, status: :ok
      end
    end

    # PUT /api/vibes/:id/restore
    def restore
      @vibe = Vibe.unscoped.find(params[:id])
      @vibe.update(deleted_at: nil)
      render json: { success: true, data: vibe_json(@vibe), errors: [] }, status: :ok
    end

    private

    def set_vibe
      @vibe = Vibe.unscoped.find(params[:id])
    end

    def vibe_params
      params.require(:vibe).permit(:name, :color, :image)
    end

    def vibe_json(vibe)
      {
        id: vibe.id,
        name: vibe.name,
        color: vibe.color,
        deleted_at: vibe.deleted_at,
        image_url: vibe.image.attached? ? url_for(vibe.image) : nil,
        in_use: vibe.orders.exists?
      }
    end
  end
end
