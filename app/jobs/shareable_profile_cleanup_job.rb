# frozen_string_literal: true

class ShareableProfileCleanupJob < ApplicationJob
  queue_as :default

  def perform(*_args)
    ShareableProfile.where(created_at: ..1.hour.ago).destroy_all
  end
end
