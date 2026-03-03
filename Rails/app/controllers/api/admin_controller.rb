module Api
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
