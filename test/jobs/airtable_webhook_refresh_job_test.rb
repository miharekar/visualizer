# frozen_string_literal: true

require "test_helper"

class AirtableWebhookRefreshJobTest < ActiveJob::TestCase
  test "refreshes the webhook payload for airtable_info" do
    stub = stub_request(:post, "https://api.airtable.com/v0/bases/#{airtable_infos(:miha).base_id}/webhooks/#{airtable_infos(:miha).webhook_id}/refresh")
      .to_return(status: 200, body: "{}", headers: {})

    AirtableWebhookRefreshJob.perform_now(airtable_infos(:miha))

    assert_requested(stub)
  end
end
