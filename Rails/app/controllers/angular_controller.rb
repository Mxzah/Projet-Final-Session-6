# frozen_string_literal: true

# Serves the Angular SPA for all non-API routes
class AngularController < ActionController::Base
  def index
    render file: "#{Rails.root}/public/index.html", layout: false
  end
end
