class CreemWebhookHandler
  EVENTS = %w[
    checkout_completed
    subscription_paid
    subscription_update
    subscription_canceled
    subscription_expired
    subscription_trialing
    subscription_scheduled_cancel
    subscription_unpaid
    subscription_active
    subscription_paused
    subscription_past_due
  ].freeze

  attr_reader :payload

  def initialize(request)
    payload = request.body.read
    raise Creem::SignatureVerificationError unless valid_signature?(payload, request.headers["creem-signature"])

    @payload = JSON.parse(payload)
  end

  def handle
    method = payload["eventType"].to_s.tr(".", "_")
    __send__(method) if EVENTS.include?(method)
  end

  private

  def checkout_completed
    @payload = {"object" => Creem.new.get_subscription(payload.dig("object", "subscription", "id"))}
    update_premium_expiry
  end

  def update_premium_expiry
    user = User.find_by(creem_customer_id:) || User.find_by(id: metadata_user_id) || User.find_by(email:)
    raise Creem::UserNotFoundError unless user

    user.update!(creem_customer_id:, premium_expires_at:)
  end
  alias_method :subscription_paid, :update_premium_expiry
  alias_method :subscription_update, :update_premium_expiry
  alias_method :subscription_canceled, :update_premium_expiry
  alias_method :subscription_expired, :update_premium_expiry
  alias_method :subscription_trialing, :update_premium_expiry
  alias_method :subscription_scheduled_cancel, :update_premium_expiry
  alias_method :subscription_unpaid, :update_premium_expiry
  alias_method :subscription_active, :update_premium_expiry
  alias_method :subscription_paused, :update_premium_expiry
  alias_method :subscription_past_due, :update_premium_expiry

  def creem_customer_id
    payload.dig("object", "customer", "id")
  end

  def metadata_user_id
    payload.dig("object", "metadata", "user_id")
  end

  def email
    payload.dig("object", "customer", "email")
  end

  def premium_expires_at
    Time.zone.parse(payload.dig("object", "current_period_end_date"))
  end

  def valid_signature?(payload, signature)
    secret = Rails.application.credentials.creem.webhook_secret
    return false if secret.blank? || signature.blank?

    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(digest, signature)
  end
end
