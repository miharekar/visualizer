# frozen_string_literal: true

Rack::MiniProfiler.config.enable_hotwire_turbo_drive_support = true
Rack::MiniProfiler.config.position = "bottom-right"
Rack::MiniProfiler.config.storage_options = {url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" }}
Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
