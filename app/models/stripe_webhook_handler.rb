# frozen_string_literal: true

class StripeWebhookHandler
  attr_reader :event

  def initialize(request)
    @event = Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      ENV["STRIPE_WEBHOOK_SECRET"]
    )
  end

  def handle
    method = event.type.tr(".", "_")
    __send__(method) if respond_to?(method, true)
  end

  private

  def invoice_payment_succeeded
    return unless event.data.object.subscription && user

    subscription = Stripe::Subscription.retrieve(event.data.object.subscription)
    user.update(premium_expires_at: Time.zone.at(subscription.current_period_end))
  end

  def user
    @user ||= User.find_by(stripe_customer_id: event.data.object.customer)
  end
end
