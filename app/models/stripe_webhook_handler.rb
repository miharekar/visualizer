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

  def customer_subscription_deleted
    user = User.find_by(stripe_customer_id: event.data.object.customer)
    return unless user

    user.update!(premium: false)
  end
end
