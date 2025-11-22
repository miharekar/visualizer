if Rails.env.local?
  require "prosopite/middleware/rack"
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
end
