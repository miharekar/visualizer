# frozen_string_literal: true

class StripeController < ApplicationController
  skip_before_action :verify_authenticity_token

  def create
    StripeWebhookHandler.new(request).handle
    head :ok
  rescue Oj::ParseError, Stripe::SignatureVerificationError
    head :bad_request
  end
end
