class OpenAi
  API_ENDPOINT = "https://api.openai.com/v1/responses".freeze
  API_KEY = Rails.application.credentials.open_ai.api_key
  CONFIG = YAML.load_file(Rails.root.join("config", "openai_prompt.yml")).deep_symbolize_keys.freeze

  def message(content, attempt: 1)
    uri = URI(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request["Authorization"] = "Bearer #{API_KEY}"
    request["Content-Type"] = "application/json"

    request_body = {
      model: CONFIG[:model],
      input: CONFIG[:prompt] % {scraped_content: content},
      max_output_tokens: CONFIG[:max_output_tokens],
      reasoning: {effort: CONFIG[:reasoning_effort]}
    }
    request.body = request_body.to_json

    response = http.request(request)
    raise "Failed to get response from OpenAI: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    model_response = JSON.parse(response.body)
    model_response["output"].filter_map { |o| o["content"] }.first.first["text"]
  rescue StandardError
    raise if attempt >= 3 || response&.code != "529"

    attempt += 1
    retry
  end
end
