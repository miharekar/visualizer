class SharedShotCleanupJob < ApplicationJob
  queue_as :low

  def perform
    SharedShot.where(created_at: ..1.hour.ago).destroy_all
  end
end
