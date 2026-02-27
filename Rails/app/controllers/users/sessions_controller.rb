# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user, only: :destroy

  # POST /resource/sign_in
  def create
    user = User.find_for_authentication(email: params[:user][:email])

    if user && user.valid_password?(params[:user][:password])
      if user.active_for_authentication?
        sign_in(:user, user)
        render json: {
          success: true,
          data: {
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            type: user.type,
            redirect_to: compute_redirect_for(user)
          }
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: [ "Invalid email or password" ]
        }, status: :ok
      end
    else
      render json: {
        success: false,
        data: nil,
        errors: [ "Invalid email or password" ]
      }, status: :ok
    end
  end

  # DELETE /resource/sign_out
  def destroy
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    respond_to_on_destroy
  end

  private

  def respond_to_on_destroy
    render json: { success: true }, status: :ok
  end

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
