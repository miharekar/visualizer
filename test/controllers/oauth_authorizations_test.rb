require "test_helper"

class OauthAuthorizationsTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    @application = Doorkeeper::Application.create!(name: "Test App", owner: @user, redirect_uri: "https://example.com/callback", scopes: "read", confidential: false)
    @challenge = Base64.urlsafe_encode64(Digest::SHA256.digest("verifier"), padding: false)
  end

  test "approval with S256 challenge stores it on the grant" do
    sign_in @user

    assert_difference -> { Doorkeeper::AccessGrant.count }, 1 do
      post oauth_authorization_url, params: authorization_params(code_challenge_method: "S256")
    end

    assert_redirected_to(/\Ahttps:\/\/example\.com\/callback\?code=/)
    grant = Doorkeeper::AccessGrant.last
    assert_equal @challenge, grant.code_challenge
    assert_equal "S256", grant.code_challenge_method
  end

  test "plain challenge method is rejected" do
    sign_in @user

    get oauth_authorization_url, params: authorization_params(code_challenge_method: "plain")

    assert_response :bad_request
    assert_includes response.body, "code_challenge_method must be S256."
    assert_not_includes response.body, "plain"
  end

  private

  def authorization_params(**extra)
    {client_id: @application.uid, redirect_uri: @application.redirect_uri, response_type: "code", scope: "read", code_challenge: @challenge}.merge(extra)
  end
end
