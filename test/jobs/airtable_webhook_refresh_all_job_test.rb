# frozen_string_literal: true

require "test_helper"

class AirtableWebhookRefreshAllJobTest < ActiveJob::TestCase
  test "enqueues jobs for all infos" do
    AirtableWebhookRefreshAllJob.perform_now

    airtable_infos.map do |airtable_info|
      assert_enqueued_with(job: AirtableWebhookRefreshJob, args: [airtable_info], queue: "default")
    end
  end
end
