# frozen_string_literal: true

# Prevent browser from caching index.html (Angular SPA entry point).
# JS/CSS chunks have unique hashes so they can be cached forever,
# but index.html must always be fresh to pick up new chunk references.
class NoCacheIndex
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    path = env["PATH_INFO"]
    if path == "/" || path == "/index.html"
      headers["cache-control"] = "no-cache, no-store, must-revalidate"
      headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
      headers["pragma"] = "no-cache"
      headers["expires"] = "0"
    end
    [status, headers, body]
  end
end

Rails.application.config.middleware.insert_after ActionDispatch::Static, NoCacheIndex
