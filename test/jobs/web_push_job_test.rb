require "test_helper"

class WebPushJobTest < ActiveJob::TestCase
  test "destroys an invalid stored subscription without sending" do
    subscription = PushSubscription.new(user: create(:user), endpoint: "https://169.254.169.254/push", p256dh_key: "key", auth_key: "auth")
    subscription.save!(validate: false)

    assert_difference -> { PushSubscription.count }, -1 do
      WebPushJob.perform_now(subscription, title: "Title", body: "Body")
    end
  end
end
