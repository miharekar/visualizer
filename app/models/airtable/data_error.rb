module Airtable
  class DataError < StandardError
    attr_reader :data, :response

    def initialize(message, data: nil, response: nil)
      super(message)
      @data = data
      @response = response
    end

    def matches_error_type?(types)
      Array(types).intersect?(airtable_error_types)
    end

    private

    def airtable_error_types
      @airtable_error_types ||= airtable_errors.filter_map { |error| error["type"] || error["error"] }.uniq
    end

    def airtable_errors
      @airtable_errors ||= [airtable_body["error"], airtable_body["errors"]].compact.flatten
    end

    def airtable_body
      @airtable_body ||= Oj.safe_load(message) || {}
    end
  end
end
