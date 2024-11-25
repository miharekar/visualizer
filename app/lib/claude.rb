class Claude
  MODEL = "claude-3-5-haiku-20241022".freeze
  API_ENDPOINT = "https://api.anthropic.com/v1/messages".freeze
  API_KEY = Rails.application.credentials.anthropic.api_key

  def message(content, attempt: 1)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["x-api-key"] = API_KEY
    request["anthropic-version"] = "2023-06-01"
    request["content-type"] = "application/json"
    request.body = {model: MODEL, max_tokens: 500, messages: [{role: "user", content:}]}.to_json

    response = http.request(request)
    raise "Failed to fetch page: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue StandardError
    raise if attempt >= 3 || response&.code != "529"

    attempt += 1
    retry
  end
end
