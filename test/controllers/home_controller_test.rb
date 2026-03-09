require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "show renders without updates" do
    Update.delete_all

    get root_url

    assert_response :success
    assert_not_includes response.body, "Latest Updates"
  end
end
