# frozen_string_literal: true

class DuplicateStripeSubscriptionsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    active_subscriptions = {}
    Stripe::Customer.list(limit: 100, expand: ["data.subscriptions"]).auto_paging_each do |customer|
      customer.subscriptions.each do |subscription|
        if subscription.status == "active"
          active_subscriptions[customer.email] ||= []
          active_subscriptions[customer.email] << subscription.id
        end
      end
    end
    active_subscriptions.select { |email, subscriptions| subscriptions.count > 1 }.each do |email, subscriptions|
      Appsignal.set_message("Duplicate subscription for #{email}")
    end
  end
end
