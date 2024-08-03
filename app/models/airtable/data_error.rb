module Airtable
  class DataError < StandardError
    prepend MemoWise

    attr_reader :data, :response

    def initialize(data: nil, response: nil)
      @data = data
      @response = response
      super(airtable_errors.map { |e| "#{e["type"] || e["error"]}: #{e["message"]}" }.join(", "))
    end

    def matches_error_type?(types)
      Array(types).intersect?(airtable_error_types)
    end

    private

    memo_wise def airtable_error_types
      airtable_errors.filter_map { |error| error["type"] || error["error"] }.uniq
    end

    memo_wise def airtable_errors
      [airtable_body["error"], airtable_body["errors"]].compact.flatten
    end

    memo_wise def airtable_body
      body = response.try(:body)
      return {} unless body

      Oj.safe_load(body)
    end
  end
end
