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
end
