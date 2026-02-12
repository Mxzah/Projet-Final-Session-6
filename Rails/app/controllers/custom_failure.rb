class CustomFailure < Devise::FailureApp
  def http_status
    # Si l'utilisateur existe et a un bon mot de passe mais est inactif
    if request.format == :json
      user = User.unscoped.find_by(email: request.params.dig(:user, :email))
      if user && user.valid_password?(request.params.dig(:user, :password)) && !user.active_for_authentication?
        return 401
      end
    end
    200
  end

  def respond
    if request.format == :json
      json_failure
    else
      super
    end
  end

  def json_failure
    # Détermine le message approprié basé sur l'état de l'utilisateur
    user = User.unscoped.find_by(email: request.params.dig(:user, :email))
    message = if user && user.valid_password?(request.params.dig(:user, :password)) && !user.active_for_authentication?
                I18n.t("devise.failure.inactive")
              else
                i18n_message
              end

    self.status = http_status
    self.content_type = 'application/json'
    self.response_body = {
      success: false,
      errors: [message]
    }.to_json
  end
end
