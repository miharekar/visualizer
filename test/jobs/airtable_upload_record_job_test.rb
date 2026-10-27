require "test_helper"

class AirtableUploadRecordJobTest < ActiveJob::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = create(:user, :with_airtable)
    @identity = @user.identities.first
    @shot = create(:shot, user: @user, skip_airtable_sync: true)
    info = @identity.airtable_info
    stub_request(:patch, "https://api.airtable.com/v0/#{info.base_id}/#{info.tables["Shots"]["id"]}")
      .to_return(status: 422, body: {error: {type: "TOO_MANY_RECORDS_IN_BASE", message: "Base is full"}}.to_json)
  end

  test "base full emails the user at most once a day" do
    assert_enqueued_emails 1 do
      2.times { AirtableUploadRecordJob.perform_now(@shot) }
    end

    travel 1.day + 1.minute do
      assert_enqueued_emails 1 do
        AirtableUploadRecordJob.perform_now(@shot)
      end
    end
  end
end
