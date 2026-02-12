# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_signed_out_user, only: :destroy

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
          last_name: resource.last_name,
          type: resource.type
        }
      }, status: :ok
    else
      # Vérifier si l'utilisateur existe mais est inactif
      user = User.unscoped.find_by(email: params[:user][:email])

      if user && user.valid_password?(params[:user][:password]) && !user.active_for_authentication?
        render json: {
          success: false,
          errors: ['Vous devez être connecté pour accéder à cette ressource']
        }, status: :unauthorized
      else
        render json: {
          success: false,
          errors: ['Email ou mot de passe invalide']
        }, status: :ok
      end
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
