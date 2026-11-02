require "test_helper"

class OauthTokensTest < ActionDispatch::IntegrationTest
  setup do
    @application = Doorkeeper::Application.create!(name: "Test App", owner: create(:user), redirect_uri: "urn:ietf:wg:oauth:2.0:oob", scopes: "read")
  end

  test "client credentials grant is rejected" do
    post oauth_token_url, params: {grant_type: "client_credentials", client_id: @application.uid, client_secret: @application.plaintext_secret}

    assert_response :bad_request
    assert_equal "unsupported_grant_type", response.parsed_body["error"]
  end

  test "refresh token grant still works" do
    token = Doorkeeper::AccessToken.create!(application: @application, resource_owner_id: create(:user).id, scopes: "read", expires_in: 1.week, use_refresh_token: true)

    post oauth_token_url, params: {grant_type: "refresh_token", refresh_token: token.plaintext_refresh_token, client_id: @application.uid, client_secret: @application.plaintext_secret}

    assert_response :success
    assert response.parsed_body["access_token"].present?
  end

  test "authorization code with PKCE needs the right verifier" do
    verifier = SecureRandom.urlsafe_base64(32)
    challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false)
    @application.update!(confidential: false)
    grant = create_grant(code_challenge: challenge, code_challenge_method: "S256")

    post oauth_token_url, params: token_params(grant, code_verifier: "wrong")

    assert_response :bad_request
    assert_equal "invalid_grant", response.parsed_body["error"]

    post oauth_token_url, params: token_params(grant, code_verifier: verifier)

    assert_response :success
    assert response.parsed_body["access_token"].present?
  end

  test "authorization code without PKCE works with client secret" do
    grant = create_grant

    post oauth_token_url, params: token_params(grant, client_secret: @application.plaintext_secret)

    assert_response :success
    assert response.parsed_body["access_token"].present?
  end

  private

  def create_grant(**attributes)
    Doorkeeper::AccessGrant.create!(application: @application, resource_owner_id: create(:user).id, scopes: "read", expires_in: 10.minutes, redirect_uri: @application.redirect_uri, **attributes)
  end

  def token_params(grant, **extra)
    {grant_type: "authorization_code", code: grant.plaintext_token, redirect_uri: @application.redirect_uri, client_id: @application.uid}.merge(extra)
  end
end
