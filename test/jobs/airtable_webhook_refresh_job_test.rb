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
      error_response = {errors: [{type: error_case[:type], message: "Error message"}]}.to_json
      stub_request(:post, @refresh_url).to_return(status: error_case[:status], body: error_response, headers: {})

      assert_difference -> { AirtableInfo.count }, -1 do
        AirtableWebhookRefreshJob.perform_now(@airtable_info)
      end

      assert_raises(ActiveRecord::RecordNotFound) { @airtable_info.reload }
    end
  end

  test "logs error to Appsignal for other error types" do
    error_response = {error: {type: "UNKNOWN_ERROR", message: "Unknown error occurred"}}.to_json
    stub_request(:post, @refresh_url).to_return(status: 500, body: error_response, headers: {})

    # Create a simple mock object
    mock = Object.new
    mock.instance_variable_set(:@called, false)
    mock.define_singleton_method(:set_error) do |error, &block|
      @called = true
      assert_instance_of Airtable::DataError, error
      transaction = Object.new
      transaction.define_singleton_method(:set_tags) do |tags|
        assert_equal @user.id, tags[:user_id]
      end
      block.call(transaction)
    end

    # Replace Appsignal.set_error with our mock method
    Appsignal.singleton_class.alias_method :original_set_error, :set_error
    Appsignal.define_singleton_method(:set_error) { |*args, &block| mock.set_error(*args, &block) }

    assert_no_difference -> { AirtableInfo.count } do
      AirtableWebhookRefreshJob.perform_now(@airtable_info)
    end

    assert_nothing_raised { @airtable_info.reload }

    # Verify our mock was called
    assert mock.instance_variable_get(:@called), "Appsignal.set_error was not called"

    # Restore original method
    Appsignal.singleton_class.alias_method :set_error, :original_set_error
  end
end
