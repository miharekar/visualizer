require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "records client IP from Cloudflare header" do
    user = create(:user)

    post session_url, params: {email: user.email, password: "password"}, headers: {"CF-Connecting-IP" => "203.0.113.7", "X-Forwarded-For" => "203.0.113.7, 162.158.1.1, 10.0.0.2, 10.0.1.2"}

    assert_equal "203.0.113.7", user.sessions.sole.ip_address
  end
end
