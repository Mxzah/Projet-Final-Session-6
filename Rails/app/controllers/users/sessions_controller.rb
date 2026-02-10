# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
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
    render json: { success: signed_out }, status: :ok
  end
end
