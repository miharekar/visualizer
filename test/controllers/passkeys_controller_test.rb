require "test_helper"
require "webauthn/fake_client"

class PasskeysControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    @client = WebAuthn::FakeClient.new(Rails.configuration.webauthn_origin)
    @user = create(:user)
    challenge = WebAuthn::Credential.options_for_create(user: {id: @user.webauthn_id, name: @user.email}).challenge
    credential = WebAuthn::Credential.from_create(@client.create(challenge:, user_verified: true))
    credential.verify(challenge, user_verification: true)
    @user.webauthn_credentials.create!(external_id: credential.id, public_key: credential.public_key, nickname: "Phone")
  end

  test "sign in options require user verification" do
    post sign_in_passkeys_url, as: :json

    assert_response :success
    assert_equal "required", response.parsed_body["userVerification"]
  end

  test "callback signs in with user verification" do
    post callback_passkeys_url, params: assertion(user_verified: true), as: :json

    assert_response :success
    assert_equal 1, @user.sessions.count
  end

  test "callback rejects assertions without user verification" do
    post callback_passkeys_url, params: assertion(user_verified: false), as: :json

    assert_response :unauthorized
    assert_empty @user.sessions
  end

  test "callback is rate limited" do
    10.times do
      post callback_passkeys_url, params: assertion(user_verified: true).merge("id" => "unknown"), as: :json
      assert_response :unauthorized
    end

    post callback_passkeys_url, params: assertion(user_verified: true), as: :json

    assert_response :too_many_requests
    assert_empty @user.sessions
  end

  private

  def assertion(user_verified:)
    post sign_in_passkeys_url, as: :json
    @client.get(challenge: response.parsed_body["challenge"], user_verified:)
  end
end
