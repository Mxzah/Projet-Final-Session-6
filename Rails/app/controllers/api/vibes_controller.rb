# frozen_string_literal: true

module Api
  # CRUD operations for restaurant vibes/ambiances
  class VibesController < AdminController
    skip_before_action :authenticate_user!, only: [ :index ]
    skip_before_action :require_admin!, only: [ :index ]
    before_action :set_vibe, only: %i[update destroy restore]

    # GET /api/vibes
    def index
      base = current_user&.type == "Administrator" ? Vibe.unscoped.order(name: :asc) : Vibe.all.order(name: :asc)
      vibes = base.includes(:orders)
      render_success(data: vibes.map { |v| vibe_json(v) }, errors: [])
    end

    # POST /api/vibes
    def create
      vibe = Vibe.new(vibe_params)
      if vibe.save
        render_success(data: vibe_json(vibe), errors: [])
      else
        render_error(vibe.errors.full_messages)
      end
    end

    # PUT /api/vibes/:id
    def update
      if @vibe.update(vibe_params)
        render_success(data: vibe_json(@vibe), errors: [])
      else
        render_error(@vibe.errors.full_messages)
      end
    end

    # DELETE /api/vibes/:id
    def destroy
      if @vibe.orders.any?
        @vibe.soft_delete!
        render_success(data: vibe_json(@vibe), errors: [])
      else
        data = vibe_json(@vibe)
        @vibe.destroy
        render_success(data: data, errors: [])
      end
    end

    # PUT /api/vibes/:id/restore
    def restore
      @vibe.update(deleted_at: nil)
      render_success(data: vibe_json(@vibe), errors: [])
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
        image: if vibe.image.attached?
                 { url: rails_storage_proxy_path(vibe.image), filename: vibe.image.blob.filename.to_s,
                   content_type: vibe.image.blob.content_type, byte_size: vibe.image.blob.byte_size }
               end,
        in_use: vibe.orders.loaded? ? vibe.orders.any? : vibe.orders.exists?
      }
    end
  end
end
