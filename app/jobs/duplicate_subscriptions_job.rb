class DuplicateSubscriptionsJob < ApplicationJob
  ACTIVE_STATUSES = %w[active on_trial trialing].freeze

  queue_as :low

  def perform
    all_subscriptions = lemon_squeezy_subscriptions.merge(stripe_subscriptions) { |_k, v1, v2| v1 + v2 }
    all_subscriptions.select { |_email, ids| ids.size > 1 }.each do |email, subscriptions|
      Appsignal.set_message("Duplicate subscription for #{email}: #{subscriptions.join(", ")}")
    end
  end

  private

  def lemon_squeezy_subscriptions
    LemonSqueezy.new.all_subscriptions
      .select { |sub| ACTIVE_STATUSES.include?(sub.dig("attributes", "status")) }
      .group_by { |sub| sub.dig("attributes", "user_email") }
      .transform_values { |subs| subs.map { |sub| sub["id"] } }
  end

  def stripe_subscriptions
    active_subscriptions = {}
    Stripe::Customer.list(limit: 100, expand: ["data.subscriptions"]).auto_paging_each do |customer|
      customer.subscriptions.each do |subscription|
        next unless ACTIVE_STATUSES.include?(subscription.status)

        active_subscriptions[customer.email] ||= []
        active_subscriptions[customer.email] << subscription.id
      end
    end
    active_subscriptions
  end
end
