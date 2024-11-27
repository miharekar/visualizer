require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require "freezolite/auto"

module Visualizer
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks misc])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    config.active_storage.analyzers = []
    config.exceptions_app = routes
    config.log_tags = {
      evt: {name: "http.request.handled"},
      http: lambda { |request|
        http_headers = request.headers.to_h.select { |key, _value| key.start_with?("HTTP_") }.transform_keys { |key| key.sub(/^HTTP_/, "").downcase }
        @sensitive_data_filter ||= ActiveSupport::ParameterFilter.new(Rails.configuration.filter_parameters)
        @sensitive_data_filter.filter(headers: http_headers, ip: request.remote_ip, request_id: request.request_id, url: request.original_url, referer: request.referer, useragent: request.user_agent)
      },
      network: ->(request) { {bytes_written: request.content_length} }
    }
    config.logger = ActiveSupport::TaggedLogging.logger($stdout)
  end
end
