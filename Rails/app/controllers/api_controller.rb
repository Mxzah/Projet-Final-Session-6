# frozen_string_literal: true

class ApiController < ApplicationController
  protected

  def render_success(attributes = {})
    render json: { success: true }.merge(attributes), status: :ok
  end

  def render_error(errors)
    errors = [errors] unless errors.is_a?(Array)
    render json: { success: false, errors: errors }, status: :ok
  end
end
