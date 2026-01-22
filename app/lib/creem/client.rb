require "net/http"
require "json"
require "uri"

class Creem
  class Client
    attr_reader :api_key, :uri, :request_class, :data, :params

    def initialize(path, method: :get, data: nil, params: {})
      @api_key = Rails.application.credentials.creem.api_key
      @uri = URI.parse(BASE_URL + path)
      @request_class = Net::HTTP.const_get(method.to_s.capitalize)
      @data = data
      @params = params
    end

    def make_request
      handle_response(get_response)
    end

    private

    def get_response
      uri.query = URI.encode_www_form(params) if params.present?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 10
      http.request(build_request)
    end

    def build_request
      request_class.new(uri).tap do
        it["Content-Type"] = "application/json"
        it["x-api-key"] = api_key
        it.body = data.to_json if data.present?
      end
    end

    def handle_response(response)
      if response.is_a?(Net::HTTPSuccess)
        JSON.parse(response.body)
      else
        error = begin
          JSON.parse(response.body)
        rescue JSON::ParserError
          nil
        end
        message = error&.dig("message") || response.message
        raise APIError.new(message, response.code.to_i), "Creem API Error (#{response.code}): #{message}"
      end
    end
  end
end
