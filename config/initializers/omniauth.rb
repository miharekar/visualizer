# The login button is a normal GET link. OmniAuth 2 defaults to POST-only
# request phases, which otherwise falls through to Rails and resolves
# /auth/homelab_oidc as the nonexistent AuthController.
OmniAuth.config.allowed_request_methods = %i[get]

Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :airtable,
    Rails.application.credentials.dig(:airtable, :client_id),
    Rails.application.credentials.dig(:airtable, :client_secret),
    scope: "data.records:read data.records:write schema.bases:read schema.bases:write webhook:manage"
  )

  if ENV["OIDC_ISSUER"].present? && ENV["OIDC_CLIENT_ID"].present? && ENV["OIDC_CLIENT_SECRET"].present?
    provider(
      :openid_connect,
      name: :homelab_oidc,
      scope: %i[openid profile email],
      response_type: :code,
      pkce: true,
      issuer: ENV.fetch("OIDC_ISSUER"),
      discovery: true,
      client_options: {
        identifier: ENV.fetch("OIDC_CLIENT_ID"),
        secret: ENV.fetch("OIDC_CLIENT_SECRET"),
        redirect_uri: ENV.fetch("OIDC_REDIRECT_URI", "#{ENV.fetch("APP_PROTOCOL", "https")}://#{ENV.fetch("APP_HOST", "localhost")}/auth/homelab_oidc/callback")
      }
    )
  end
end
