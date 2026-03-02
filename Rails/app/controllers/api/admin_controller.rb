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
        errors: [ I18n.t("controllers.admin.access_restricted") ]
      }, status: :ok
    end
  end
end
