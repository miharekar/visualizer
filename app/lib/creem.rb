require "net/http"
require "json"
require "uri"

class Creem
  class SignatureVerificationError < StandardError; end
  class UserNotFoundError < StandardError; end

  class APIError < StandardError
    attr_reader :code

    def initialize(message, code)
      @code = code
      super(message)
    end
  end

  BASE_URL = "https://#{Rails.env.local? ? 'test-' : ''}api.creem.io/v1".freeze

  def create_checkout(data)
    make_request("/checkouts", method: :post, data:)
  end

  def create_customer_portal(customer_id)
    make_request("/customers/billing", method: :post, data: {customer_id:})
  end

  private

  def make_request(path, method: :get, data: nil, params: {})
    uri = URI.parse(BASE_URL + path)
    uri.query = URI.encode_www_form(params) if params.present?

    request_class = Net::HTTP.const_get(method.to_s.capitalize)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
      http.request(build_request(request_class, uri, data))
    end

    handle_response(response)
  end

  def build_request(request_class, uri, data)
    request_class.new(uri).tap do
      it["Content-Type"] = "application/json"
      it["x-api-key"] = Rails.application.credentials.creem.api_key
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
      message = error["message"] || response.message
      raise APIError.new(message, response.code.to_i), "Creem API Error (#{response.code}): #{message}"
    end
  end
end
