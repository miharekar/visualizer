require "test_helper"

class AirtableWebhookRefreshJobTest < ActiveJob::TestCase
  setup do
    @user = create(:user, :with_airtable)
    @airtable_info = @user.identities.first.airtable_info
    @refresh_url = "https://api.airtable.com/v0/bases/#{@airtable_info.base_id}/webhooks/#{@airtable_info.webhook_id}/refresh"
  end

  test "refreshes the webhook payload for airtable_info" do
    stub = stub_request(:post, @refresh_url).to_return(status: 200, body: "{}", headers: {})
    AirtableWebhookRefreshJob.perform_now(@airtable_info)
    assert_requested(stub)
  end

  [
    {type: "NOT_FOUND", status: 404},
    {type: "INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND", status: 403},
    {type: "CANNOT_REFRESH_DISABLED_WEBHOOK", status: 400}
  ].each do |error_case|
    test "destroys airtable_info when #{error_case[:type]} error occurs and is returned in error" do
      error_response = {error: {type: error_case[:type], message: "Error message"}}.to_json
      stub_request(:post, @refresh_url).to_return(status: error_case[:status], body: error_response, headers: {})

      assert_difference -> { AirtableInfo.count }, -1 do
        AirtableWebhookRefreshJob.perform_now(@airtable_info)
      end

      assert_raises(ActiveRecord::RecordNotFound) { @airtable_info.reload }
    end
  end

  [
    {type: "NOT_FOUND", status: 404},
    {type: "INVALID_PERMISSIONS_OR_MODEL_NOT_FOUND", status: 403},
    {type: "CANNOT_REFRESH_DISABLED_WEBHOOK", status: 400}
  ].each do |error_case|
    test "destroys airtable_info when #{error_case[:type]} error occurs and is returned in errors" do
      error_response = {errors: [{error: error_case[:type], message: "Error message"}]}.to_json
      stub_request(:post, @refresh_url).to_return(status: error_case[:status], body: error_response, headers: {})

      assert_difference -> { AirtableInfo.count }, -1 do
        AirtableWebhookRefreshJob.perform_now(@airtable_info)
      end

      assert_raises(ActiveRecord::RecordNotFound) { @airtable_info.reload }
    end
  end
end
