# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.keep_original_rails_log = true
  config.lograge.logger = Appsignal::Logger.new("rails", format: Appsignal::Logger::LOGFMT)
end
