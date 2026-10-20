require "test_helper"

module Api
  class BaseControllerTest < ActionDispatch::IntegrationTest
    test "rate limit is shared across API controllers" do
      50.times do
        get api_canonical_roasters_url, as: :json
        assert_response :success
      end

      get api_shots_url, as: :json

      assert_response :too_many_requests
      assert_equal "Too many requests. Please try again later.", response.parsed_body["error"]
    end
  end
end
