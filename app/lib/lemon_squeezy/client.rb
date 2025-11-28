class LemonSqueezy
  class SignatureVerificationError < StandardError; end

  class APIError < StandardError
    attr_reader :code

    def initialize(message, code)
      @code = code
      super(message)
    end
  end

  class Client
    BASE_URL = "https://api.lemonsqueezy.com/v1".freeze

    attr_reader :api_key, :uri, :request_class, :data, :params

    def initialize(path, method: :get, data: nil, params: {})
      @api_key = Rails.application.credentials.lemon_squeezy.api_key
      @uri = URI.parse(BASE_URL + path)
      @request_class = Net::HTTP.const_get(method.to_s.capitalize)
      @data = data
      @params = params
      @results = []
    end

    def make_request(retrying: false)
      handle_response(get_response)
    rescue APIError => e
      raise if retrying || e.code != 500

      retrying = true
      sleep(1)
      retry
    end

    def paginate(current_page: 1, page_size: 100)
      @params[:page] ||= {}
      @params[:page] = @params[:page].merge(number: current_page, size: page_size)

      response = make_request
      @results += response["data"]

      if current_page >= response.dig("meta", "page", "lastPage")
        @results
      else
        paginate(current_page: current_page + 1, page_size:)
      end
    end

    private

    def encode_params(params)
      params.flat_map do |key, value|
        if value.is_a?(Hash)
          value.map { |k, v| ["#{key}[#{k}]", v] }
        else
          [[key, value]]
        end
      end
    end

    def get_response
      if params.present?
        encoded_params = encode_params(params)
        uri.query = URI.encode_www_form(encoded_params)
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.request(build_request)
    end

    def build_request
      request_class.new(uri).tap do
        it["Accept"] = "application/vnd.api+json"
        it["Content-Type"] = "application/vnd.api+json"
        it["Authorization"] = "Bearer #{api_key}"
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
        message = error&.dig("errors", 0, "detail") || response.message
        raise APIError.new(message, response.code.to_i), "Lemon Squeezy API Error (#{response.code}): #{message}"
      end
    end
  end
end
