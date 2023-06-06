# frozen_string_literal: true

if Rails.application.credentials[:rorvswild].present?
  mrsked = ENV["MRSK_CONTAINER_NAME"].to_s.split("-")

  RorVsWild.start(
    api_key: Rails.application.credentials[:rorvswild],
    deployment: {
      revision: mrsked.try(:[], 2).to_s.split("_").first
    },
    server: {
      name: "#{mrsked.try(:[], 0)}-#{mrsked.try(:[], 1)}-#{Socket.gethostname}"
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
