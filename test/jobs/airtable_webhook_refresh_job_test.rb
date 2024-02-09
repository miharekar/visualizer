# frozen_string_literal: true

require "test_helper"

class AirtableWebhookRefreshJobTest < ActiveJob::TestCase
  test "refreshes the webhook payload for airtable_info" do
    user = create(:user, :with_airtable)
    airtable_info = user.identities.first.airtable_info

    stub = stub_request(:post, "https://api.airtable.com/v0/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/refresh")
      .to_return(status: 200, body: "{}", headers: {})

    AirtableWebhookRefreshJob.perform_now(airtable_info)

    assert_requested(stub)
  end
end
