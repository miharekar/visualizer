class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked

  discard_on ActiveJob::DeserializationError, ActiveStorage::IntegrityError

  before_perform :semantic_logger_sync

  def semantic_logger_sync
    SemanticLogger.sync!
  end
end
