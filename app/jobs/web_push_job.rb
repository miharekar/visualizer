class WebPushJob < ApplicationJob
  CONTACT_EMAIL = "mailto:info@visualizer.coffee".freeze

  queue_as :default
  rescue_from(WebPush::TooManyRequests, WebPush::PushServiceError) { retry_transient_failure }

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
  rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription, WebPush::Unauthorized
    push_subscription.destroy
  end

  private

  def retry_transient_failure
    return unless executions < 3

    delay = executions**4
    jitter = determine_jitter_for_delay(delay, self.class.retry_jitter)
    retry_job(wait: delay + jitter + 2.seconds)
  end
end
