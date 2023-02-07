# frozen_string_literal: true

if Rails.application.credentials[:rorvswild].present?
  RorVsWild.start(
    api_key: Rails.application.credentials[:rorvswild],
    deployment: {
      revision: ENV["GIT_SHA"],
      description: ENV["GIT_MESSAGE"]
    }
  )
end

module RorVsWild
  class SimpleMessage < StandardError
  end

  def self.send_message(message, context = nil)
    ex = SimpleMessage.new(message)
    ex.set_backtrace(caller.drop(1))
    record_error(ex, context)
  end
end
