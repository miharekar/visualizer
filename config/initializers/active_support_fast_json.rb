# frozen_string_literal: true

module ActiveSupport
  module JSON
    def self.decode(json)
      data = ::FastJsonparser.parse(json, symbolize_keys: false)

      if ActiveSupport.parse_json_times
        convert_dates_from(data)
      else
        data
      end
    end
  end
end
