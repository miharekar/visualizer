class DuplicateStripeSubscriptionsJob < ApplicationJob
  queue_as :low

  def perform
    active_subscriptions = {}
    Stripe::Customer.list(limit: 100, expand: ["data.subscriptions"]).auto_paging_each do |customer|
      customer.subscriptions.each do |subscription|
        if subscription.status == "active"
          active_subscriptions[customer.email] ||= []
          active_subscriptions[customer.email] << subscription.id
        end
      end
    end
    active_subscriptions.select { |_email, subscriptions| subscriptions.count > 1 }.each_key do |email|
      Appsignal.set_message("Duplicate subscription for #{email}")
    end
  end
end
