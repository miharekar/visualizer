# Remove after Rails includes https://github.com/rails/rails/pull/58601.
raise "Review JSON 3 compatibility patch for updated Rails version" unless Rails.version == "8.1.3.1"

module ActiveSupport
  module JSON
    class << self
      def decode(json, options = nil)
        data = options ? ::JSON.parse(json, **options) : ::JSON.parse(json)

        ActiveSupport.parse_json_times ? convert_dates_from(data) : data
      end
      alias_method :load, :decode
    end
  end
end
