if Rails.env.local?
  require "prosopite/middleware/rack"
  Rails.configuration.middleware.use(Prosopite::Middleware::Rack)
  Prosopite.min_n_queries = 3
  Prosopite.allow_stack_paths = [
    /action_controller\/metal\/rate_limiting\.rb/,
    /mission_control\/jobs/,
    # Bounded Journal writes intentionally run each shot's validations and callbacks.
    /Journal#(?:update|undo|create)/
  ]
end
