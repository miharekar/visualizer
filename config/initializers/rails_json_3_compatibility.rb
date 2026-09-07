# Remove after Rails includes https://github.com/rails/rails/pull/58601.
require "active_record/coders/json"

raise "Review and remove Rails JSON 3 compatibility patch" unless Rails.version == "8.1.3.1"

module RailsJson3Compatibility
  module ActiveSupportJSON
    def decode(json, options = {})
      data = ::JSON.parse(json, **options)

      ActiveSupport.parse_json_times ? convert_dates_from(data) : data
    end
    alias_method :load, :decode
  end

  module ActiveRecordJSONCoder
    def initialize(encode_options: nil, decode_options: nil)
      encode_options = {escape: false}.merge(encode_options || {})
      @decode_options = decode_options
      @encoder = ActiveSupport::JSON::Encoding.json_encoder.new(encode_options)
    end

    def load(json)
      ActiveSupport::JSON.decode(json, @decode_options) if json.present?
    end
  end
end

ActiveSupport::JSON.singleton_class.prepend(RailsJson3Compatibility::ActiveSupportJSON)
ActiveRecord::Coders::JSON.prepend(RailsJson3Compatibility::ActiveRecordJSONCoder)
