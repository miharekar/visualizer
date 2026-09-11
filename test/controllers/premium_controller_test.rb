require "test_helper"

class PremiumControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
  end

  test "index directs JSON requests to the API documentation" do
    get premium_index_url(format: :json)

    assert_response :not_acceptable
    assert_equal "application/json", response.media_type
    assert_equal({
      "error" => "This is not an API endpoint.",
      "api_docs" => "https://apidocs.visualizer.coffee"
    }, response.parsed_body)
  end

  test "index renders HTML with wildcard accept" do
    get premium_index_url, headers: {"Accept" => "*/*"}

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "Access your complete shot history"
  end
end
