# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json

  before_action :configure_sign_up_params, only: [:create]

  # POST /resource
  def create
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?

    if resource.persisted?
      if resource.active_for_authentication?
        sign_up(resource_name, resource)
        render json: {
          success: true,
          data: { email: resource.email, first_name: resource.first_name, last_name: resource.last_name }
        }, status: :ok
      else
        expire_data_after_sign_in!
        render json: {
          success: false,
          data: nil,
          errors: ['Compte créé mais inactif']
        }, status: :ok
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
      render json: {
        success: false,
        data: nil,
        errors: resource.errors.full_messages
      }, status: :ok
    end
  end

  protected

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :type])
  end
end
