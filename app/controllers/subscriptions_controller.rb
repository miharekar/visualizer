class SubscriptionsController < ApplicationController
  before_action :check_admin!

  def index
    @subscriptions = Subscription.order(:status, :started_at).includes(:user)
    @refunds = YAML.unsafe_load_file("refunds.yml")
    @payments = YAML.unsafe_load_file("payments.yml").to_h do |stripe_customer_id, pis|
      sum = pis.sum do |pi|
        refund = @refunds[pi.id]&.sum(&:amount) || 0
        pi.amount - refund
      end
      [stripe_customer_id, (sum / 100.0)]
    end
  end
end
