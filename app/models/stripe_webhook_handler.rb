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

  def customer_subscription_updated
    update_premium_expiry(event.data.object.id)
  end

  def customer_subscription_created
    update_premium_expiry(event.data.object.id)
  end

  def update_premium_expiry(subscription_id)
    return unless subscription_id && user

    subscription = Stripe::Subscription.retrieve(subscription_id)
    raise "Invalid subscription items for #{subscription_id}" unless subscription.items.count == 1

    user.update(premium_expires_at: Time.zone.at(subscription.items.first.current_period_end))
  end

  def user
    @user ||= find_by_stripe_customer_id || find_by_email
  end

  def find_by_stripe_customer_id
    User.find_by(stripe_customer_id: event.data.object.customer)
  end

  def find_by_email
    customer = Stripe::Customer.retrieve(event.data.object.customer)
    user = User.find_by(email: customer.email)

    if user
      user&.update(stripe_customer_id: event.data.object.customer)
      user
    else
      raise "No user found for #{event.data.object.customer} or #{event.data.object.customer_email}!"
    end
  end
end
