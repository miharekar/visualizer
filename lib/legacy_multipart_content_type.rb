class LegacyMultipartContentType
  def initialize(app)
    @app = app
  end

  def call(env)
    env["CONTENT_TYPE"] = env["CONTENT_TYPE"].gsub(/\s*,\s*/, "; ") if legacy_shot_upload?(env)

    @app.call(env)
  end

  private

  def legacy_shot_upload?(env)
    env["PATH_INFO"] == "/api/shots/upload" && env["CONTENT_TYPE"]&.start_with?("multipart/form-data,")
  end
end
