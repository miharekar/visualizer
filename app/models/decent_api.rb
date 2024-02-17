# frozen_string_literal: true

class DecentApi
  BASE_URL = "https://decentespresso.com/support/api"

  attr_reader :email, :token

  def initialize(email, token)
    @email = email
    @token = token
  end

  def login
    get_request("/login_test")
  end

  def serial_numbers
    get_request("/sn").split("\n")
  end

  private

  def get_request(path)
    uri = URI(BASE_URL + path)
    puts uri
    req = Net::HTTP::Get.new(uri)
    req.basic_auth(email, token)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    response = http.request(req)
    return unless response.is_a?(Net::HTTPSuccess)

    response.body.chomp
  end
end
