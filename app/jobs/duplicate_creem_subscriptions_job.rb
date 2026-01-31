class DuplicateCreemSubscriptionsJob < ApplicationJob
  queue_as :low

  def perform
    now_ms = Time.current.to_i * 1000
    transactions_by_customer = Creem.new.all_transactions.group_by { |t| t["customer"] }
    transactions_by_customer.each do |customer_id, transactions|
      active_transactions = transactions.select { now_ms.between?(it["period_start"], it["period_end"]) }
      next unless active_transactions.size > 1

      Appsignal.set_message("Duplicate Creem subscription for #{customer_id}: #{active_transactions.map { |t| t["subscription"] }.join(", ")}")
    end
  end
end
