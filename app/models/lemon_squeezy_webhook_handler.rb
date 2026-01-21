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
    premium_expires_at = subscription.dig("data", "attributes", "ends_at").presence || subscription.dig("data", "attributes", "renews_at")
    user.update(premium_expires_at:, lemon_squeezy_customer_id:)
  end

  def user
    @user ||= User.find_by(lemon_squeezy_customer_id:) || User.find_by(email:) || User.find_by(id: custom_data_user_id)
    return @user if @user

    Appsignal.set_message("No user found for #{email} / #{custom_data_user_id}")
  end

  def lemon_squeezy_customer_id
    payload.dig("data", "attributes", "customer_id")
  end

  def email
    payload.dig("data", "attributes", "user_email")
  end

  def custom_data_user_id
    payload.dig("meta", "custom_data", "user_id")
  end
end
