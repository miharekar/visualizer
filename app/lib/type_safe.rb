class TypeSafe
  class Error < StandardError; end

  API_ENDPOINT = "https://api.typesafe.ai/v1/systemone".freeze
  API_KEY = Rails.application.credentials.dig(:typesafe, :api_key)
  MODEL = "jev-latest".freeze
  RETRYABLE_CODES = %w[429 529].freeze
  MAX_ATTEMPTS = 3

  def system_one(state:, questions:)
    attempt = 1
    loop do
      response = post({model: MODEL, state:, questions:})
      return JSON.parse(response.body) if response.is_a?(Net::HTTPSuccess)
      raise Error, "TypeSafe #{response.code}: #{response.body.presence || response.message}" if attempt >= MAX_ATTEMPTS || RETRYABLE_CODES.exclude?(response.code)

      sleep(2**attempt)
      attempt += 1
    end
  end

  private

  def post(body)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{API_KEY}"
    request["Content-Type"] = "application/json"
    request.body = body.to_json
    http.request(request)
  end
end
