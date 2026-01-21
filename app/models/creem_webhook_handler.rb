class CreemWebhookHandler
  attr_reader :payload

  def initialize(request)
    payload = request.body.read
    raise Creem::SignatureVerificationError unless valid_signature?(payload, request.headers["creem-signature"])

    @payload = JSON.parse(payload)
  end

  def handle
    method = payload["eventType"].to_s.tr(".", "_")
    __send__(method) if respond_to?(method, true)
  end

  private

  def update_premium_expiry
    user = find_by_creem_customer_id || find_by_metadata_user_id || find_by_email
    raise Creem::UserNotFoundError unless user

    user.update!(
      creem_customer_id: payload.dig("object", "customer", "id"),
      premium_expires_at: Time.zone.parse(payload.dig("object", "current_period_end_date"))
    )
  end
  alias_method :subscription_paid, :update_premium_expiry
  alias_method :subscription_update, :update_premium_expiry
  alias_method :subscription_canceled, :update_premium_expiry
  alias_method :subscription_expired, :update_premium_expiry
  alias_method :subscription_trialing, :update_premium_expiry
  alias_method :subscription_scheduled_cancel, :update_premium_expiry
  alias_method :subscription_unpaid, :update_premium_expiry

  def find_by_creem_customer_id
    creem_customer_id = payload.dig("object", "customer", "id")
    User.find_by(creem_customer_id:) if creem_customer_id.present?
  end

  def find_by_metadata_user_id
    metadata_user_id = payload.dig("object", "metadata", "user_id")
    User.find_by(id: metadata_user_id) if metadata_user_id.present?
  end

  def find_by_email
    email = payload.dig("object", "customer", "email")
    User.find_by(email:) if email.present?
  end

  def valid_signature?(payload, signature)
    secret = Rails.application.credentials.creem.webhook_secret
    return false if secret.blank? || signature.blank?

    digest = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
    ActiveSupport::SecurityUtils.secure_compare(digest, signature)
  end
end
