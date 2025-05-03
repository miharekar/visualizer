class WebPushJob < ApplicationJob
  CONTACT_EMAIL = "mailto:info@visualizer.coffee".freeze

  queue_as :default

  def perform(push_subscription, title:, body:, path: "/")
    WebPush.payload_send(
      message: {title:, body:, data: {path:}}.to_json,
      endpoint: push_subscription.endpoint,
      p256dh: push_subscription.p256dh_key,
      auth: push_subscription.auth_key,
      vapid: {
        subject: CONTACT_EMAIL,
        public_key: Rails.application.credentials.webpush.public_key,
        private_key: Rails.application.credentials.webpush.private_key
      }
    )
  rescue WebPush::ExpiredSubscription, WebPush::PushServiceError, WebPush::InvalidSubscription
    push_subscription.destroy
  end
end
