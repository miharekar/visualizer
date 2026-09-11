class BadRequestMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      ActionDispatch::Request.new(env).query_parameters
    rescue ActionController::BadRequest
      return bad_request
    end

    @app.call(env)
  rescue Rack::Multipart::BoundaryTooLongError
    bad_request
  end

  private

  def bad_request
    [400, {"content-type" => "text/plain", "content-length" => "11"}, ["Bad Request"]]
  end
end
