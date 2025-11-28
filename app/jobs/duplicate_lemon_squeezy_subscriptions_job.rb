class DuplicateLemonSqueezySubscriptionsJob < ApplicationJob
  ACTIVE_STATUSES = %w[active on_trial].freeze

  queue_as :low

  def perform
    find_duplicate_subscriptions.each do |email, subscriptions|
      Appsignal.set_message("Duplicate subscription for #{email}: #{subscriptions.join(", ")}")
    end
  end

  private

  def find_duplicate_subscriptions
    LemonSqueezy.new.all_subscriptions
      .select { ACTIVE_STATUSES.include?(it.dig("attributes", "status")) }
      .group_by { it.dig("attributes", "user_email") }
      .transform_values { it.map { it["id"] } }
      .select { |_email, ids| ids.size > 1 }
  end
end
