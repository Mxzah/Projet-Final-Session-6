module Api
  class SessionsController < ApplicationController
    # GET /api/current_user
    def current_user
      if user_signed_in?
        render json: {
          success: true,
          data: {
            authenticated: true,
            user: {
              email: current_user.email,
              first_name: current_user.first_name,
              last_name: current_user.last_name,
              type: current_user.type
            },
            redirect_to: compute_redirect_for(current_user)
          },
          errors: []
        }, status: :ok
      else
        render json: {
          success: true,
          data: {
            authenticated: false,
            user: nil
          },
          errors: []
        }, status: :ok
      end
    end

    private

    def compute_redirect_for(user)
      case user.type
      when "Cook"
        "/kitchen"
      when "Administrator"
        "/admin/tables"
      else
        if Order.open.where(client_id: user.id).exists?
          "/menu"
        else
          "/form"
        end
      end
    end
  end
end
