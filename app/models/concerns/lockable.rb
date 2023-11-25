# frozen_string_literal: true

module Lockable
  def with_lock(key, ttl_ms = 10_000)
    lock_manager.lock(key, ttl_ms) do |locked|
      yield if locked
    end
  end

  private

  def lock_manager
    @lock_manager ||= Redlock::Client.new(redis_servers)
  end

  def redis_servers
    Rails.env.test? ? [] : [Sidekiq.redis_pool]
  end
end
