class ApplicationController < ActionController::API
  before_action :set_locale
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  private

  def set_locale
    locale = request.headers["X-Locale"] || request.headers["Accept-Language"]&.split(",")&.first&.split("-")&.first
    I18n.locale = I18n.available_locales.map(&:to_s).include?(locale) ? locale : :fr
  end

  def render_not_found(_exception)
    render json: {
      success: false,
      data: nil,
      errors: [ I18n.t("controllers.common.not_found") ]
    }, status: :ok
  end

  def render_parameter_missing(exception)
    render json: {
      success: false,
      data: nil,
      errors: [ exception.message ]
    }, status: :ok
  end
end
