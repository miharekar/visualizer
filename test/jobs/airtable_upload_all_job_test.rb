require "test_helper"

class AirtableUploadAllJobTest < ActiveJob::TestCase
  test "does not upload for non-premium users" do
    user = create(:user, :with_airtable, premium_expires_at: nil)
    create(:shot, user:)

    assert_nothing_raised { AirtableUploadAllJob.perform_now(user) }
  end
end
