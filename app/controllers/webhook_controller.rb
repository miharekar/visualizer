class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token

  def lemon_squeezy
    LemonSqueezyWebhookHandler.new(request).handle
    head :ok
  rescue JSON::ParserError, LemonSqueezy::SignatureVerificationError
    head :bad_request
  end

  def creem
    CreemWebhookHandler.new(request).handle
    head :ok
  rescue JSON::ParserError, Creem::SignatureVerificationError, Creem::UserNotFoundError => e
    Appsignal.report_error(e) { Appsignal.add_tags(webhook_id: params["id"]) }
    head :bad_request
  end
end
