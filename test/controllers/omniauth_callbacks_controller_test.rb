require "test_helper"

class OmniauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    host! "example.com"
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:airtable] = OmniAuth::AuthHash.new(
      provider: "airtable",
      uid: "airtable-uid",
      credentials: {token: "token", refresh_token: "refresh", expires_at: 1.hour.from_now.to_i}
    )
  end

  teardown do
    OmniAuth.config.test_mode = false
    OmniAuth.config.mock_auth[:airtable] = nil
  end

  test "airtable callback connects premium users" do
    user = create(:user, :premium)
    sign_in(user)

    assert_enqueued_with(job: AirtableUploadAllJob, args: [user]) do
      get "/auth/airtable/callback"
    end

    assert_redirected_to shots_path
    assert_equal 1, user.identities.by_provider(:airtable).count
  end

  test "airtable callback ignores non-premium users" do
    user = create(:user)
    sign_in(user)

    assert_no_enqueued_jobs do
      get "/auth/airtable/callback"
    end

    assert_redirected_to premium_index_path
    assert_empty user.identities
  end

  test "airtable callback requires authentication" do
    assert_no_difference "Identity.count" do
      get "/auth/airtable/callback"
    end

    assert_redirected_to new_session_url
  end
end
