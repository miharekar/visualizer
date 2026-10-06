require "test_helper"

class DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  test "direct uploads are disabled" do
    host! "example.com"
    params = {blob: {filename: "image.png", byte_size: 4, checksum: "CY9rzUYh03PK3k6DJie09g==", content_type: "image/png"}}

    post rails_direct_uploads_url, params:, as: :json
    assert_response :not_found

    sign_in create(:user, :admin)
    post rails_direct_uploads_url, params:, as: :json
    assert_response :not_found
  end
end
