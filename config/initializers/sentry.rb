# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
  config.send_default_pii = true
  config.breadcrumbs_logger = %i[sentry_logger active_support_logger http_logger]

  filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
  config.before_send = lambda do |event, _hint|
    filter.filter(event.to_hash)
  end

  config.traces_sample_rate = 0.2
end
