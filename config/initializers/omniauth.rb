Rails.application.config.middleware.use OmniAuth::Builder do
  provider(
    :airtable,
    Rails.application.credentials.dig(:airtable, :client_id),
    Rails.application.credentials.dig(:airtable, :client_secret),
    scope: "data.records:read data.records:write schema.bases:read schema.bases:write webhook:manage"
  )
end
