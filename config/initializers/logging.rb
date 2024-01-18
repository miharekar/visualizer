# frozen_string_literal: true

appsignal_logger = Appsignal::Logger.new("rails")
Rails.logger.broadcast_to(appsignal_logger)
