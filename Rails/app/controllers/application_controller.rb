class ApplicationController < ActionController::API
  before_action :set_locale
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

  private

  def set_locale
    locale = request.headers['X-Locale'] || request.headers['Accept-Language']&.split(',')&.first&.split('-')&.first
    I18n.locale = I18n.available_locales.map(&:to_s).include?(locale) ? locale : :fr
  end

  def render_not_found(exception)
    render json: {
      success: false,
      data: nil,
      errors: [exception.message]
    }, status: :ok
  end
end
