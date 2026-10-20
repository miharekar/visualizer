class CloudflareRemoteIp
  def initialize(app, origin_secret = Rails.application.credentials.dig(:cloudflare, :origin_secret))
    @app = app
    @origin_secret = origin_secret
  end

  def call(env)
    cloudflare_ip = env["HTTP_CF_CONNECTING_IP"]
    ActionDispatch::Request.new(env).remote_ip = cloudflare_ip if cloudflare_ip.present? && from_cloudflare?(env)
    @app.call(env)
  end

  private

  def from_cloudflare?(env)
    @origin_secret.present? && ActiveSupport::SecurityUtils.secure_compare(env["HTTP_X_ORIGIN_SECRET"].to_s, @origin_secret)
  end
end
