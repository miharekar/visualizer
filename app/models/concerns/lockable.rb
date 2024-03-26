module Lockable
  def with_lock!(name, ttl: 30, attempts: 1, &block)
    raise ArgumentError, "Block required" unless block

    PgLock.new(name:, ttl:, attempts:).lock!(&block)
  end
end
