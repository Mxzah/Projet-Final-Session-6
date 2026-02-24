Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:4200', 'http://127.0.0.1:4200'

    resource '*',
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: ['Authorization']
  end
end
