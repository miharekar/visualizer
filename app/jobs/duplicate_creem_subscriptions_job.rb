class DuplicateCreemSubscriptionsJob < ApplicationJob
  queue_as :low

  def perform
    transactions_by_customer = Creem.new.all_transactions.group_by { |t| t["customer"] }
    transactions_by_customer.select { |_, transactions| transactions.size > 1 }.each do |customer_id, transactions|
      Appsignal.set_message("Duplicate Creem subscription for #{customer_id}: #{transactions.map { |t| t["subscription"] }.join(", ")}")
    end
  end
end
