require "test_helper"

class BadRequestMiddlewareTest < ActiveSupport::TestCase
  test "invalid query encoding is rejected before reaching downstream middleware" do
    app = BadRequestMiddleware.new(->(_env) { flunk "Downstream app must not be called" })
    env = Rack::MockRequest.env_for("https://www.visualizer.coffee/?%ADd+allow_url_include%3D1+%ADd+auto_prepend_file%3Dphp://input", method: "POST")

    status, headers, body = app.call(env)

    assert_equal 400, status
    assert_equal "text/plain", headers["content-type"]
    assert_equal "11", headers["content-length"]
    assert_equal ["Bad Request"], body
  end

  test "oversized multipart boundaries still return bad request" do
    app = BadRequestMiddleware.new(->(_env) { raise Rack::Multipart::BoundaryTooLongError })

    assert_equal 400, app.call(Rack::MockRequest.env_for("/"))[0]
  end

  test "downstream exceptions are not swallowed" do
    [RuntimeError, ActionController::BadRequest].each do |error|
      app = BadRequestMiddleware.new(->(_env) { raise error })

      assert_raises(error) { app.call(Rack::MockRequest.env_for("/")) }
    end
  end
end

class BadRequestMiddlewareIntegrationTest < ActionDispatch::IntegrationTest
  setup { host! "www.visualizer.coffee" }

  test "malformed query on www returns bad request" do
    post "/?%ADd+allow_url_include%3D1+%ADd+auto_prepend_file%3Dphp://input"

    assert_response :bad_request
    assert_equal "Bad Request", response.body
  end

  test "valid www requests preserve path and query when redirected" do
    get "/community?search=coffee"

    assert_response :moved_permanently
    assert_redirected_to "http://visualizer.coffee/community?search=coffee"
  end
end
