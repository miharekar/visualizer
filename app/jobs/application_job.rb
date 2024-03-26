class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked

  discard_on ActiveJob::DeserializationError, ActiveStorage::IntegrityError

  rescue_from(Exception) do |exception|
    Appsignal.send_error(exception)
    raise exception
  end
end
