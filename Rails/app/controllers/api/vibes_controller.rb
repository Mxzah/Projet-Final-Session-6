module Api
  class VibesController < ApplicationController
    before_action :authenticate_user!

    # GET /api/vibes
    def index
      vibes = Vibe.all.order(name: :asc)

      render json: {
        success: true,
        data: vibes.map { |v| { id: v.id, name: v.name, color: v.color } },
        errors: []
      }, status: :ok
    end
  end
end
