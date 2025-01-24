require "net/http"
require "json"
require "uri"

class LemonSqueezy
  class APIError < StandardError; end
  class SignatureVerificationError < StandardError; end
  BASE_URL = "https://api.lemonsqueezy.com/v1".freeze

  attr_reader :api_key

  def initialize
    @api_key = Rails.application.credentials.lemon_squeezy.api_key
  end

  def get_customer(id)
    make_request(:get, "/customers/#{id}")
  end

  def get_customers(params: {})
    make_request(:get, "/customers", params:)
  end

  def get_subscription(id)
    make_request(:get, "/subscriptions/#{id}")
  end

  def get_subscriptions(params: {})
    make_request(:get, "/subscriptions", params:)
  end

  def create_checkout(data: nil)
    make_request(:post, "/checkouts", data:)
  end

  private

  def make_request(method, path, data: nil, params: {})
    uri = URI.parse("#{BASE_URL}#{path}")

    encoded_params = params.flat_map do |key, value|
      if value.is_a?(Hash)
        value.map { |k, v| ["#{key}[#{k}]", v] }
      else
        [[key, value]]
      end
    end

    uri.query = URI.encode_www_form(encoded_params) unless encoded_params.empty?

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(build_request(method, uri, data))

    if response.is_a?(Net::HTTPSuccess)
      JSON.parse(response.body)
    else
      error = begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        nil
      end
      message = error&.dig("errors", 0, "detail") || response.message
      raise APIError, "Lemon Squeezy API Error (#{response.code}): #{message}"
    end
  end

  def build_request(method, uri, data)
    request_class = Net::HTTP.const_get(method.to_s.capitalize)
    request_class.new(uri).tap do |request|
      request["Accept"] = "application/vnd.api+json"
      request["Content-Type"] = "application/vnd.api+json"
      request["Authorization"] = "Bearer #{api_key}"
      request.body = data.to_json if data.present?
    end
  end
end
