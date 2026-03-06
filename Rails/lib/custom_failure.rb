# frozen_string_literal: true

# Custom Devise failure response returning JSON instead of redirects
class CustomFailure < Devise::FailureApp
  def respond
    self.status = 200
    self.content_type = "application/json"
    self.response_body = {
      success: false,
      data: nil,
      errors: [I18n.t("controllers.sessions.unauthenticated")],
      session_expired: true
    }.to_json
  end
end
