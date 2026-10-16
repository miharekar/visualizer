require "test_helper"

class PushSubscriptionTest < ActiveSupport::TestCase
  test "accepts push service endpoints" do
    assert subscription("https://fcm.googleapis.com/fcm/send/abc").valid?
    assert subscription("https://web.push.apple.com/abc").valid?
    assert subscription("https://updates.push.services.mozilla.com/wpush/v2/abc").valid?
    assert subscription("https://wns2-par02p.notify.windows.com/w/?token=abc").valid?
  end

  test "rejects other endpoints" do
    [
      "http://fcm.googleapis.com/fcm/send/abc",
      "https://169.254.169.254/latest/meta-data",
      "https://fcm.googleapis.com.evil.test/abc",
      "https://evilfcm.googleapis.com.test/abc",
      "https://fcm.googleapis.com@evil.test/abc",
      "https://fcm.googleapis.com:6379/abc",
      "not a url",
      ""
    ].each { assert_not subscription(it).valid?, it }
    assert_not subscription(nil).valid?
  end

  private

  def subscription(endpoint)
    PushSubscription.new(user: build_stubbed(:user), endpoint:)
  end
end
