# frozen_string_literal: true

require "test_helper"

class RefreshTokenJobTest < ActiveJob::TestCase
  test "refreshes token when expired" do
    stub = stub_request(:post, "https://airtable.com/oauth2/v1/token")
      .with(body: {"grant_type" => "refresh_token", "refresh_token" => "refresh_token"})
      .to_return(status: 200, body: {refresh_token: "new_refresh_token", access_token: "new_access_token", expires_at: 1.hour.from_now.to_i}.to_json, headers: {"Content-Type" => "application/json"})

    identity = identities(:miha)
    identity.update(expires_at: 1.day.ago)
    RefreshTokenJob.perform_now(identity)

    assert_requested(stub)
    identity.reload
    assert_equal "new_access_token", identity.token
    assert_equal "new_refresh_token", identity.refresh_token
    assert_in_delta 1.hour.from_now, identity.expires_at, 1.second
  end

  test "does not refresh token when not expired" do
    identity = identities(:miha)
    identity.update(expires_at: 1.hour.from_now)
    RefreshTokenJob.perform_now(identity)
    identity.reload
    assert_equal "access_token", identity.token
    assert_equal "refresh_token", identity.refresh_token
    assert_in_delta 1.hour.from_now, identity.expires_at, 1.second
  end
end
