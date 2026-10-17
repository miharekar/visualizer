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
    stub_request(:get, "https://api.airtable.com/v0/meta/bases")
      .to_return(status: 200, body: {bases: [{id: "appCreate", name: "Visualizer", permissionLevel: "create"}]}.to_json)
    stub_request(:get, "https://api.airtable.com/v0/bases/appCreate/webhooks")
      .to_return(status: 200, body: {webhooks: []}.to_json)
    stub_request(:post, "https://api.airtable.com/v0/bases/appCreate/webhooks")
      .to_return(status: 200, body: {id: "achNew"}.to_json)

    assert_enqueued_with(job: AirtableUploadAllJob, args: [user]) do
      get "/auth/airtable/callback"
    end

    assert_redirected_to shots_path
    assert_equal 1, user.identities.by_provider(:airtable).count
    assert_equal "appCreate", user.identities.by_provider(:airtable).first.airtable_info.base_id
  end

  test "airtable callback disconnects when no base can be created in" do
    user = create(:user, :premium)
    sign_in(user)
    stub_request(:get, "https://api.airtable.com/v0/meta/bases")
      .to_return(status: 200, body: {bases: [{id: "appEdit", name: "Visualizer", permissionLevel: "edit"}]}.to_json)

    assert_no_enqueued_jobs only: AirtableUploadAllJob do
      get "/auth/airtable/callback"
    end

    assert_redirected_to shots_path
    assert_match "Creator", flash[:alert]
    assert_empty user.identities.by_provider(:airtable)
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
