# frozen_string_literal: true

class SharedShotCleanupJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    SharedShot.where(created_at: ..1.hour.ago).destroy_all
  end
end
