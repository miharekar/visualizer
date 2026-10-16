class PushSubscription < ApplicationRecord
  PUSH_SERVICE_HOSTS = %w[fcm.googleapis.com push.services.mozilla.com push.apple.com notify.windows.com].freeze

  belongs_to :user

  validate :endpoint_must_be_push_service

  private

  def endpoint_must_be_push_service
    errors.add(:endpoint, "is not a supported push service") unless push_service_endpoint?
  end

  def push_service_endpoint?
    uri = URI.parse(endpoint.to_s)
    host = uri.host&.downcase
    uri.scheme == "https" && uri.port == 443 && host.present? && PUSH_SERVICE_HOSTS.any? { host == it || host.end_with?(".#{it}") }
  rescue URI::InvalidURIError
    false
  end
end

# == Schema Information
#
# Table name: push_subscriptions
# Database name: primary
#
#  id         :uuid             not null, primary key
#  auth_key   :string
#  endpoint   :string
#  p256dh_key :string
#  user_agent :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :uuid             not null
#
# Indexes
#
#  index_push_subscriptions_on_user_id  (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
