class PopulateStripeJob < ApplicationJob
  prepend MemoWise

  queue_as :default

  def perform
    populate_customers
    populate_subscriptions
  end

  private

  def populate_customers
    Stripe::Customer.list(limit: 100).auto_paging_each do |stripe_customer|
      upsert_customer(stripe_customer)
    end
  end

  def populate_subscriptions
    Stripe::Subscription.list(status: "all", limit: 100).auto_paging_each do |stripe_subscription|
      upsert_subscription(stripe_subscription)
    end
  end

  def upsert_customer(stripe_customer)
    customer = Customer.find_or_initialize_by(stripe_id: stripe_customer.id)
    customer.user = User.find_by(stripe_customer_id: stripe_customer.id)
    customer.name = stripe_customer.name
    customer.email = stripe_customer.email
    customer.address = stripe_customer.address
    payments = stripe_payments[stripe_customer.id].presence || []
    customer.payments = payments.pluck(:id)
    refunds = stripe_refunds.values_at(*customer.payments).flatten.compact
    customer.refunds = refunds.pluck(:id)
    customer.amount = payments.sum(&:amount) - refunds.sum(&:amount)
    customer.save!
  rescue ActiveRecord::RecordInvalid => e
    Appsignal.report_error(e)
  end

  def upsert_subscription(stripe_subscription)
    subscription = Subscription.find_or_initialize_by(stripe_id: stripe_subscription.id)
    subscription.customer = Customer.find_by(stripe_id: stripe_subscription.customer)
    subscription.status = stripe_subscription.status
    subscription.interval = stripe_subscription.plan.interval
    subscription.started_at = Time.zone.at(stripe_subscription.start_date)
    subscription.ended_at = Time.zone.at(stripe_subscription.ended_at) if stripe_subscription.ended_at
    subscription.cancel_at = Time.zone.at(stripe_subscription.cancel_at) if stripe_subscription.cancel_at
    subscription.cancelled_at = Time.zone.at(stripe_subscription.canceled_at) if stripe_subscription.canceled_at
    subscription.cancellation_details = stripe_subscription.cancellation_details
    subscription.save!
  rescue ActiveRecord::RecordInvalid => e
    Appsignal.report_error(e)
  end

  memo_wise def stripe_payments
    Stripe::PaymentIntent.list(limit: 100).auto_paging_each.with_object({}) do |payment_intent, payments|
      next unless payment_intent.status == "succeeded"

      payments[payment_intent.customer] ||= []
      payments[payment_intent.customer] << payment_intent
    end
  end

  memo_wise def stripe_refunds
    Stripe::Refund.list(limit: 100).auto_paging_each.with_object({}) do |refund, refunds|
      refunds[refund.payment_intent] ||= []
      refunds[refund.payment_intent] << refund
    end
  end
end
