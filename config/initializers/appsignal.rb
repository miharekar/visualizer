# frozen_string_literal: true

module Appsignal
  class SimpleMessage < StandardError
  end

  def self.send_message(message, ...)
    ex = SimpleMessage.new(message)
    ex.set_backtrace(caller.drop(1))
    send_error(ex, ...)
  end
end
