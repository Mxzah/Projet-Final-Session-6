# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user, only: :destroy

  # POST /resource/sign_in
  def create
    user = User.find_by(email: params[:user][:email])

    if user && user.valid_password?(params[:user][:password])
      if user.active_for_authentication?
        sign_in(:user, user)
        render json: {
          success: true,
          data: {
            email: user.email,
            first_name: user.first_name,
            last_name: user.last_name,
            type: user.type
          }
        }, status: :ok
      else
        render json: {
          success: false,
          data: nil,
          errors: ["Votre compte n'est pas encore activé"]
        }, status: :ok
      end
    else
      render json: {
        success: false,
        data: nil,
        errors: ['Email ou mot de passe invalide']
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
end
