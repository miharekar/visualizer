module Turnstile
  TURNSTILE_URI = URI("https://challenges.cloudflare.com/turnstile/v0/siteverify")

  def verify_turnstile
    return true unless Rails.env.production?

    response = Net::HTTP.post(TURNSTILE_URI, turnstile_params.to_json, "Content-Type" => "application/json")
    JSON.parse(response.body)["success"] == true
  end

  private

  def turnstile_params
    {
      secret: Rails.application.credentials.dig(:cloudflare, :secret_key),
      response: params["cf-turnstile-response"],
      remoteip: request.headers["CF-Connecting-IP"]
    }
  end
end
