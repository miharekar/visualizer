# frozen_string_literal: true

Rack::MiniProfiler.config.enable_hotwire_turbo_drive_support = true
Rack::MiniProfiler.config.storage_options = {url: ENV["CACHE_REDIS_URL"]}
Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
