class UnconfirmedUserCleanupJob < ApplicationJob
  queue_as :low

  def perform
    stale = User.where(confirmed_at: nil, disabled_at: nil, created_at: ..7.days.ago)
    stale.where(id: Shot.select(:user_id)).find_each { it.update!(disabled_at: Time.current) }
    stale.destroy_all
  end
end
