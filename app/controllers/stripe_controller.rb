# frozen_string_literal: true

class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    StripeWebhookHandler.new(request).handle
    head :ok
  rescue Stripe::SignatureVerificationError
    render json: {error: "Invalid signature"}, status: :bad_request
  rescue JSON::ParserError
    render json: {error: "Invalid JSON"}, status: :bad_request
  end
end
