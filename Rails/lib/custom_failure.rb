class CustomFailure < Devise::FailureApp
  def respond
    self.status = 200
    self.content_type = 'application/json'
    self.response_body = {
      success: false,
      data: nil,
      errors: [ "Invalid email or password" ]
    }.to_json
  end
end
