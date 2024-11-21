class StripeWebhookHandler
  attr_reader :event

  def initialize(request)
    @event = Stripe::Webhook.construct_event(
      request.body.read,
      request.env["HTTP_STRIPE_SIGNATURE"],
      Rails.application.credentials.stripe&.webhook_secret
    )
  end

  def handle
    method = event.type.tr(".", "_")
    __send__(method) if respond_to?(method, true)
  end

  private

  def invoice_payment_succeeded
    update_premium_expiry(event.data.object.subscription)
  end

  def customer_subscription_updated
    update_premium_expiry(event.data.object.id)
  end

  def update_premium_expiry(subscription_id)
    return unless subscription_id && user

    subscription = Stripe::Subscription.retrieve(subscription_id)
    user.update(premium_expires_at: Time.zone.at(subscription.current_period_end) + 1.day)
  end

  def user
    @user ||= find_by_stripe_customer_id || find_by_email
  end

  def find_by_stripe_customer_id
    User.find_by(stripe_customer_id: event.data.object.customer)
  end

  def find_by_email
    Appsignal.set_message("Customer #{event.data.object.customer_email} did not have a Stripe customer ID attached!")
    user = User.find_by(email: event.data.object.customer_email)
    user&.update(stripe_customer_id: event.data.object.customer)
    user
  end
end
