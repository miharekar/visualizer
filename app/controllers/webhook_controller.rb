class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def lemon_squeezy
    LemonSqueezyWebhookHandler.new(request).handle
    head :ok
  rescue JSON::ParserError, LemonSqueezy::SignatureVerificationError
    head :bad_request
  end
end
