class WebPushJob < ApplicationJob
  queue_as :default

  def perform(title:, message:, endpoint:, p256dh_key:, auth_key:)
    message_json = {
      title:,
      body: message,
      icon: "/android-chrome-192x192.png"
    }.to_json

    WebPush.payload_send(
      message: message_json,
      endpoint:,
      p256dh: p256dh_key,
      auth: auth_key,
      vapid: {
        subject: "mailto:hello@joyofrails.com",
        public_key: Rails.application.credentials.webpush.public_key,
        private_key: Rails.application.credentials.webpush.private_key
      }
    )
  end
end
