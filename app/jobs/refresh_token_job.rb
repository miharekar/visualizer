class RefreshTokenJob < ApplicationJob
  queue_as :high

  retry_on PgLock::UnableToLockError, wait: :polynomially_longer

  def perform(identity)
    identity.refresh_token!
    return unless identity.airtable?

    AirtableShotUploadAllJob.set(wait: 2.minutes).perform_later(identity.user)
  end
end
