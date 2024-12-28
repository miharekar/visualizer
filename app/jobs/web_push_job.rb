class WebPushJob < ApplicationJob
  ICON_PATH = "/android-chrome-192x192.png".freeze
  CONTACT_EMAIL = "mailto:info@visualizer.coffee".freeze

  queue_as :default

  def perform(push_subscription, title:, body:)
    WebPush.payload_send(
      message: {
        title:,
        body:,
        icon: ICON_PATH,
        data: {url: "/shots/123"}
      }.to_json,
      endpoint: push_subscription.endpoint,
      p256dh: push_subscription.p256dh_key,
      auth: push_subscription.auth_key,
      vapid: {
        subject: CONTACT_EMAIL,
        public_key: Rails.application.credentials.webpush.public_key,
        private_key: Rails.application.credentials.webpush.private_key
      }
    )
  end
end
