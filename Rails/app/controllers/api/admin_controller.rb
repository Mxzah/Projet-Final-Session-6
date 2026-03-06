# frozen_string_literal: true

module Api
  # Admin dashboard statistics endpoint
  class AdminController < ApiController
    before_action :authenticate_user!
    before_action :require_admin!

    private

    def require_admin!
      return if current_user&.type == "Administrator"

      render_error(I18n.t("controllers.admin.access_restricted"))
    end
  end
end
