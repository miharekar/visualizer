class SystemOne
  class Error < StandardError; end

  ACCOUNT_ID = Rails.application.credentials.dig(:cloudflare_ai, :account_id)
  API_TOKEN = Rails.application.credentials.dig(:cloudflare_ai, :api_token)
  API_ENDPOINT = "https://api.cloudflare.com/client/v4/accounts/#{ACCOUNT_ID}/ai/run/@cf/cloudflare/clef".freeze
  MODEL = "clef".freeze
  RETRYABLE_CODES = %w[429 500 502 503 504].freeze
  MAX_ATTEMPTS = 3

  def evaluate(state:, questions:)
    attempt = 1
    loop do
      response = post({model: MODEL, state:, questions:})
      return JSON.parse(response.body)["result"] if response.is_a?(Net::HTTPSuccess)
      raise Error, "SystemOne #{response.code}: #{response.body.presence || response.message}" if attempt >= MAX_ATTEMPTS || RETRYABLE_CODES.exclude?(response.code)

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
    request["Authorization"] = "Bearer #{API_TOKEN}"
    request["Content-Type"] = "application/json"
    request.body = body.to_json
    http.request(request)
  end
end
