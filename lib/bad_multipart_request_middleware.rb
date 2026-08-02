class BadMultipartRequestMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env)
  rescue Rack::Multipart::BoundaryTooLongError
    [400, {"content-type" => "text/plain", "content-length" => "11"}, ["Bad Request"]]
  end
end
