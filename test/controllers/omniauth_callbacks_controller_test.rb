require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @issuer = "https://auth.example.test"
    @previous_issuer = ENV["OIDC_ISSUER"]
    ENV["OIDC_ISSUER"] = @issuer
  end

  teardown do
    ENV["OIDC_ISSUER"] = @previous_issuer
  end

  test "requires POST for the OIDC login request" do
    assert_equal [:post], OmniAuth.config.allowed_request_methods
  end

  test "rejects a direct GET without raising a missing controller error" do
    host! "example.com"
    get "/auth/homelab_oidc"

    assert_response :method_not_allowed
    assert_equal "POST", response.headers["Allow"]
  end

  test "signs in an identity matched by issuer and subject" do
    user = create(:user)
    create(:identity, user:, provider: "homelab_oidc", uid: "subject-1")

    get homelab_oidc_callback_url, env: oidc_env("subject-1")

    assert_redirected_to shots_url
    assert_equal user.id, Session.order(:created_at).last.user_id
  end

  test "does not link an unrecognised subject by matching email" do
    user = create(:user, email: "owner@example.test")

    get homelab_oidc_callback_url, env: oidc_env("new-subject", "owner@example.test")

    assert_redirected_to new_session_url
    assert_not user.identities.exists?(provider: "homelab_oidc", uid: "new-subject")
  end

  test "provisions a new confirmed user for an unrecognised OIDC subject" do
    assert_difference ["User.count", "Identity.count", "Session.count"], 1 do
      get homelab_oidc_callback_url, env: oidc_env("new-subject", "new@example.test")
    end

    user = User.find_by!(email: "new@example.test")
    assert user.confirmed?
    assert_redirected_to shots_url
    assert_equal user.id, Session.order(:created_at).last.user_id
    assert user.identities.exists?(provider: "homelab_oidc", uid: "new-subject")
  end

  test "does not provision an OIDC user without an email" do
    assert_no_difference ["User.count", "Identity.count", "Session.count"] do
      get homelab_oidc_callback_url, env: oidc_env("missing-email", "")
    end

    assert_redirected_to new_session_url
  end

  private

  def oidc_env(subject, email = "user@example.test")
    {"omniauth.auth" => {
      "provider" => "homelab_oidc",
      "uid" => subject,
      "info" => {"email" => email},
      "extra" => {"raw_info" => {"iss" => @issuer}}
    }}
  end
end
