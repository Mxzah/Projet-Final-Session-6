# frozen_string_literal: true

# Base application controller with locale management
class ApplicationController < ActionController::API
  before_action :set_locale
  before_action :check_session_expiry
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_parameter_missing

  SESSION_TTL = 24.hours

  private

  def check_session_expiry
    return unless session[:created_at].present?

    if Time.zone.parse(session[:created_at]) < SESSION_TTL.ago
      reset_session
      render json: {
        success: false,
        data: nil,
        errors: [I18n.t("controllers.sessions.expired")],
        session_expired: true
      }, status: :ok
    end
  end

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
