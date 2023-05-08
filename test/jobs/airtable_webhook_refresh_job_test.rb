# frozen_string_literal: true

require "test_helper"

class AirtableWebhookRefreshJobTest < ActiveJob::TestCase
  test "refreshes all webhook payloads" do
    stubs = airtable_infos.map do |airtable_info|
      stub_request(:post, "https://api.airtable.com/v0/bases/#{airtable_info.base_id}/webhooks/#{airtable_info.webhook_id}/refresh").
        to_return(status: 200, body: "", headers: {})
    end

    AirtableWebhookRefreshJob.perform_now

    stubs.each do |stub|
      assert_requested(stub)
    end
  end
end
