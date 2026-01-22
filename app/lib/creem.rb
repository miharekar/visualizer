require "creem/client"

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
    Client.new("/checkouts", method: :post, data:).make_request
  end

  def create_customer_portal(customer_id)
    Client.new("/customers/billing", method: :post, data: {customer_id:}).make_request
  end
end
