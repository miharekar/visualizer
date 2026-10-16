require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  test "reset removes every way back into the account" do
    user = create(:user)
    sign_in(user)
    application = Doorkeeper::Application.create!(name: "Test App", owner: create(:user), redirect_uri: "urn:ietf:wg:oauth:2.0:oob")
    Doorkeeper::AccessGrant.create!(application:, resource_owner_id: user.id, redirect_uri: application.redirect_uri, expires_in: 10.minutes)
    Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, expires_in: 1.week)
    user.webauthn_credentials.create!(external_id: "credential", public_key: "key", nickname: "Phone")
    user.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/abc", p256dh_key: "key", auth_key: "auth")

    put password_url(user.password_reset_token), params: {password: "new-password", password_confirmation: "new-password"}

    assert_redirected_to new_session_url
    user.reload
    assert_empty user.sessions
    assert_empty user.access_grants
    assert_empty user.access_tokens
    assert_empty user.webauthn_credentials
    assert_empty user.push_subscriptions
  end

  test "blank reset changes nothing" do
    user = create(:user)
    sign_in(user)
    application = Doorkeeper::Application.create!(name: "Test App", owner: create(:user), redirect_uri: "urn:ietf:wg:oauth:2.0:oob")
    Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, expires_in: 1.week)
    user.webauthn_credentials.create!(external_id: "credential", public_key: "key", nickname: "Phone")
    user.push_subscriptions.create!(endpoint: "https://fcm.googleapis.com/fcm/send/abc", p256dh_key: "key", auth_key: "auth")

    put password_url(user.password_reset_token), params: {password: "", password_confirmation: ""}

    assert_response :bad_request
    user.reload
    assert_not_empty user.sessions
    assert_not_empty user.access_tokens
    assert_not_empty user.webauthn_credentials
    assert_not_empty user.push_subscriptions
  end
end
