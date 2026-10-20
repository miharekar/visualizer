require "test_helper"

class CloudflareRemoteIpTest < ActiveSupport::TestCase
  FORWARDED_FOR = "203.0.113.7, 162.158.1.1, 10.0.0.2, 10.0.1.2".freeze

  test "trusts the Cloudflare IP when the origin secret matches" do
    assert_equal "203.0.113.7", remote_ip("secret", "HTTP_X_ORIGIN_SECRET" => "secret")
  end

  test "ignores the Cloudflare IP when the origin secret is wrong or missing" do
    assert_equal "162.158.1.1", remote_ip("secret", "HTTP_X_ORIGIN_SECRET" => "wrong")
    assert_equal "162.158.1.1", remote_ip("secret")
  end

  test "ignores the Cloudflare IP when no origin secret is configured" do
    [nil, ""].each do |configured|
      assert_equal "162.158.1.1", remote_ip(configured, "HTTP_X_ORIGIN_SECRET" => "")
    end
  end

  private

  def remote_ip(configured_secret, headers = {})
    seen = nil
    downstream = ->(env) { [200, {}, [seen = ActionDispatch::Request.new(env).remote_ip]] }
    app = ActionDispatch::RemoteIp.new(CloudflareRemoteIp.new(downstream, configured_secret))
    app.call(Rack::MockRequest.env_for("/", {"HTTP_CF_CONNECTING_IP" => "203.0.113.7", "HTTP_X_FORWARDED_FOR" => FORWARDED_FOR, "REMOTE_ADDR" => "127.0.0.1"}.merge(headers)))
    seen
  end
end
