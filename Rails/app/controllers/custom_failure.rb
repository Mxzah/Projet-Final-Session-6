class CustomFailure < Devise::FailureApp
  def respond
    if request.format == :json
      json_failure
    else
      super
    end
  end

  def json_failure
    # Toujours retourner 200 avec success: false et un message générique en français
    self.status = 200
    self.content_type = 'application/json'
    self.response_body = {
      success: false,
      data: nil,
      errors: ["Email ou mot de passe invalide"]
    }.to_json
  end
end
