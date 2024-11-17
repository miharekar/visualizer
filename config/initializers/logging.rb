appsignal_logger = Appsignal::Logger.new("rails", format: Appsignal::Logger::LOGFMT)
SemanticLogger.add_appender(logger: appsignal_logger, formatter: :logfmt)
