# frozen_string_literal: true

class SponsorshipsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_signature

  def create
    SponsorshipsMailer.webhook(params).deliver_now
    head :ok
  end

  def verify_signature
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), ENV["SPONSORSHIP_SECRET"], request.body.read)
    head :unauthorized unless Rack::Utils.secure_compare("sha256=#{signature}", request.env["HTTP_X_HUB_SIGNATURE_256"])
  end
end
