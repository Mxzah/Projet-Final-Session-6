# frozen_string_literal: true

module Api
  # Session status check endpoint
  class SessionsController < ApplicationController
    # GET /api/current_user
    def show
      user = warden.user(:user)
      if user
        render json: {
          success: true,
          data: {
            authenticated: true,
            user: {
              email: user.email,
              first_name: user.first_name,
              last_name: user.last_name,
              type: user.type
            },
            redirect_to: compute_redirect_for(user)
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
      when "Waiter"
        "/server"
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
