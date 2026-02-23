class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def render_not_found(exception)
    render json: {
      success: false,
      data: nil,
      errors: [exception.message]
    }, status: :ok
  end
end
