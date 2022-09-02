# frozen_string_literal: true

if Rails.application.credentials.cloudinary
  Cloudinary.config do |config|
    config.cloud_name = Rails.application.credentials.cloudinary&.cloud_name
    config.api_key = Rails.application.credentials.cloudinary&.api_key
    config.api_secret = Rails.application.credentials.cloudinary&.secret
    config.secure = true
  end
end
