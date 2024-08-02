class RefreshTokenJob < ApplicationJob
  queue_as :high

  retry_on PgLock::UnableToLockError, wait: :polynomially_longer

  def perform(identity)
    identity.refresh_token!
  end
end
