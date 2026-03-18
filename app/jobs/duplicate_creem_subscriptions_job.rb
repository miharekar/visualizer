class DuplicateCreemSubscriptionsJob < ApplicationJob
  queue_as :low

  def perform
    Creem.new.all_subscriptions.group_by { |subscription| subscription.dig("customer", "id") }.each do |customer_id, subscriptions|
      active_subscriptions = subscriptions.select do |subscription|
        start_at = subscription["current_period_start_date"].present? ? Time.zone.parse(subscription["current_period_start_date"]) : nil
        end_at = subscription["current_period_end_date"].present? ? Time.zone.parse(subscription["current_period_end_date"]) : nil

        start_at.present? && end_at.present? && Time.current.between?(start_at, end_at)
      end
      next unless active_subscriptions.size > 1

      Appsignal.set_message("Duplicate Creem subscription for #{customer_id}: #{active_subscriptions.map { |subscription| subscription["id"] }.join(", ")}")
    end
  end
end
