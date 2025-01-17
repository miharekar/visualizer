class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def stripe
    StripeWebhookHandler.new(request).handle
    head :ok
  rescue JSON::ParserError, Stripe::SignatureVerificationError
    head :bad_request
  end

  def lemon_squeezy
    LemonSqueezyWebhookHandler.new(request).handle
    head :ok
  rescue JSON::ParserError, LemonSqueezy::SignatureVerificationError
    head :bad_request
  end
end
