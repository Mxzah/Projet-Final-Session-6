module Api
  class AdminController < ApplicationController
    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      return if current_user&.type == "Administrator"

      render json: {
        success: false,
        data: nil,
        errors: ["Accès réservé aux administrateurs"]
      }, status: :ok
    end
  end
end
