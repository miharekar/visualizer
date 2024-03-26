module Airtable
  class DataError < StandardError
    attr_reader :data, :response

    def initialize(message, data: nil, response: nil)
      super(message)
      @data = data
      @response = response
    end
  end
end
