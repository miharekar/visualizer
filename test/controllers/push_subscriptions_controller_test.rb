require "test_helper"

class PushSubscriptionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user)
    sign_in(@user)
  end

  test "create saves a push service endpoint" do
    post push_subscriptions_url, params: params("https://fcm.googleapis.com/fcm/send/abc"), as: :json

    assert_response :ok
    assert_equal 1, @user.push_subscriptions.count
  end

  test "create rejects other endpoints" do
    post push_subscriptions_url, params: params("https://169.254.169.254/latest/meta-data"), as: :json

    assert_response :unprocessable_content
    assert_empty @user.push_subscriptions
  end

  test "create keeps only the ten most recent subscriptions" do
    10.times { |i| post push_subscriptions_url, params: params("https://fcm.googleapis.com/fcm/send/#{i}"), as: :json }
    post push_subscriptions_url, params: params("https://fcm.googleapis.com/fcm/send/0"), as: :json
    post push_subscriptions_url, params: params("https://fcm.googleapis.com/fcm/send/10"), as: :json

    assert_equal 10, @user.push_subscriptions.count
    assert @user.push_subscriptions.exists?(endpoint: "https://fcm.googleapis.com/fcm/send/0")
    assert_not @user.push_subscriptions.exists?(endpoint: "https://fcm.googleapis.com/fcm/send/1")
  end

  private

  def params(endpoint)
    {push_subscription: {endpoint:, p256dh_key: "key", auth_key: "auth"}}
  end
end
