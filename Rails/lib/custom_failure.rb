class CustomFailure < Devise::FailureApp
  def respond
    self.status = 200
    self.content_type = 'application/json'
    self.response_body = {
      success: false,
      errors: ['Vous devez être connecté pour accéder à cette ressource']
    }.to_json
  end
end
