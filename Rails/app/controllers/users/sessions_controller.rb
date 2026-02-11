# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user, only: :destroy
  respond_to :json

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options)

    if resource
      sign_in(resource_name, resource)
      render json: {
        success: true,
        data: {
          email: resource.email,
          first_name: resource.first_name,
          last_name: resource.last_name
        }
      }, status: :ok
    else
      render json: {
        success: false,
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
