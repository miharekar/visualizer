if Rails.env.local?
  require "prosopite/middleware/rack"
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
  Prosopite.min_n_queries = 3
end
