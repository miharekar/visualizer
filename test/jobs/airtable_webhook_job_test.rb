require "test_helper"

class AirtableWebhookJobTest < ActiveJob::TestCase
  test "does not sync for non-premium users" do
    user = create(:user, :with_airtable, premium_expires_at: nil)
    airtable_info = user.identities.first.airtable_info

    assert_nothing_raised { AirtableWebhookJob.perform_now(airtable_info) }
    assert_nil airtable_info.reload.last_cursor
  end
end
