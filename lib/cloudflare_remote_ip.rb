class CloudflareRemoteIp
  def initialize(app)
    @app = app
  end

  def call(env)
    cloudflare_ip = env["HTTP_CF_CONNECTING_IP"]
    ActionDispatch::Request.new(env).remote_ip = cloudflare_ip if cloudflare_ip.present?
    @app.call(env)
  end
end
