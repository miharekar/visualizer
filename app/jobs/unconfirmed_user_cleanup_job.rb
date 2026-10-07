class UnconfirmedUserCleanupJob < ApplicationJob
  queue_as :low

  def perform
    User.where(confirmed_at: nil, created_at: ..7.days.ago).destroy_all
  end
end
