class PopulateSubscriptionsJob < ApplicationJob
  prepend MemoWise

  queue_as :default

  def perform
    Stripe::Subscription.list(status: "all", limit: 100).auto_paging_each do |subscription|
      upsert_subscription(subscription)
    end
  end

  private

  def upsert_subscription(stripe_subscription)
    subscription = Subscription.find_or_initialize_by(stripe_id: stripe_subscription.id)
    subscription.user_id = stripe_users[stripe_subscription.customer]
    subscription.status = stripe_subscription.status
    subscription.interval = stripe_subscription.plan.interval
    subscription.started_at = Time.at(stripe_subscription.start_date)
    subscription.ended_at = Time.at(stripe_subscription.ended_at) if stripe_subscription.ended_at
    subscription.cancel_at = Time.at(stripe_subscription.cancel_at) if stripe_subscription.cancel_at
    subscription.cancelled_at = Time.at(stripe_subscription.canceled_at) if stripe_subscription.canceled_at
    subscription.cancellation_details = stripe_subscription.cancellation_details
    subscription.save!
  rescue ActiveRecord::RecordInvalid => e
    Appsignal.send_error(e)
  end

  memo_wise def stripe_users
    stripe_users = User.where.not(stripe_customer_id: nil).pluck(:stripe_customer_id, :id).to_h
  end
end
