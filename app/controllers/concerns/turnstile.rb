module Turnstile
  TURNSTILE_URI = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")

  def verify_turnstile
    return true unless Rails.env.production?
    # Self-hosted installations are normally already protected by their
    # private ingress/authentication layer and do not have the upstream
    # author's Cloudflare credentials. Keep an explicit opt-in for operators
    # who still want the external challenge.
    return true if User.self_hosted? && ENV.fetch("SELF_HOSTED_REQUIRE_TURNSTILE", "false") != "true"

    response = Net::HTTP.post(TURNSTILE_URI, turnstile_params.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)["success"] == true
  end

  private

  def turnstile_params
    {
      secret: Rails.application.credentials.dig(:cloudflare, :secret_key),
      response: params["cf-turnstile-response"],
      remoteip: request.remote_ip
    }
  end
end
