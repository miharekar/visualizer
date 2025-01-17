class LemonSqueezyWebhookHandler
  attr_reader :payload

  def initialize(request)
    payload = request.body.read
    signature = request.headers["X-Signature"]
    secret = Rails.application.credentials.lemon_squeezy&.webhook_secret
    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    raise LemonSqueezy::SignatureVerificationError unless ActiveSupport::SecurityUtils.secure_compare(digest, signature)

    @payload = JSON.parse(payload)
  end

  def handle
    method = payload.dig("meta", "event_name")
    __send__(method) if respond_to?(method, true)
  end

  private

  def subscription_created
    update_premium_expiry(payload.dig("data", "id"))
  end

  def subscription_updated
    update_premium_expiry(payload.dig("data", "id"))
  end

  def update_premium_expiry(subscription_id)
    return unless subscription_id && user

    subscription = LemonSqueezy.new.get_subscription(subscription_id)
    user.update(premium_expires_at: subscription.dig("data", "attributes", "renews_at"))
  end

  def user
    @user ||= find_by_lemon_squeezy_customer_id || find_by_email
  end

  def lemon_squeezy_customer_id
    payload.dig("data", "attributes", "customer_id")
  end

  def email
    payload.dig("data", "attributes", "user_email")
  end

  def find_by_lemon_squeezy_customer_id
    User.find_by(lemon_squeezy_customer_id:)
  end

  def find_by_email
    user = User.find_by(email:)
    if user
      user.update(lemon_squeezy_customer_id:)
      user
    else
      Appsignal.set_message("No user found for #{email}!")
    end
  end
end
