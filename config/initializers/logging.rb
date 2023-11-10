# frozen_string_literal: true

if Rails.env.production?
  console_logger = ActiveSupport::Logger.new($stdout)
  appsignal_logger = ActiveSupport::TaggedLogging.new(Appsignal::Logger.new("rails"))
  Rails.logger = ActiveSupport::BroadcastLogger.new(console_logger, appsignal_logger)
end
