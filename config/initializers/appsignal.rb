module Appsignal
  class SimpleMessage < StandardError
  end

  def self.set_message(message, ...)
    ex = SimpleMessage.new(message)
    ex.set_backtrace(caller.drop(1))
    report_error(ex, ...)
  end
end
