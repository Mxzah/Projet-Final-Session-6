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
            }
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
  end
end
