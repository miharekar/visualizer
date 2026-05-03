class DuplicateCreemSubscriptionsJob < ApplicationJob
  queue_as :low

  def perform
    Creem.new.all_subscriptions.group_by { it.dig("customer", "id") }.each do |customer_id, subscriptions|
      active_subscriptions = subscriptions.reject { it.dig("status") == "canceled" }.select do
        start_at = it["current_period_start_date"].present? ? Time.zone.parse(it["current_period_start_date"]) : nil
        end_at = it["current_period_end_date"].present? ? Time.zone.parse(it["current_period_end_date"]) : nil

        start_at.present? && end_at.present? && Time.current.between?(start_at, end_at)
      end
      next unless active_subscriptions.size > 1

      Appsignal.set_message("Duplicate Creem subscription for #{customer_id}: #{active_subscriptions.map { |subscription| subscription["id"] }.join(", ")}")
    end
  end
end
