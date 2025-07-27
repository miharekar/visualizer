module Parsers
  class Gaggimate < Base
    DATA_LABELS_MAP = {
      "cp" => "espresso_pressure",
      "fl" => "espresso_flow",
      "tp" => "espresso_pressure_goal",
      "tf" => "espresso_flow_goal",
      "tt" => "espresso_temperature_goal",
      "ct" => "espresso_temperature_mix",
      "v"  => "espresso_weight",
      "ev" => "espresso_flow_weight"
    }.freeze

    def parse
      @start_time = Time.at(json["timestamp"]).utc
      @profile_title = has_profile? ? json.dig("profile", "label") : json["profile"]
      @profile_fields = has_profile? ? json["profile"] : {"label" => json["profile"]}
      prepare_data
      set_extra
    end

    private

    def has_profile?
      json["profile"].is_a?(Hash)
    end

    def prepare_data
      @timeframe = []
      DATA_LABELS_MAP.each_value { |label| @data[label] = [] }

      json["samples"].each do |point|
        @timeframe << (point["t"] / 1000.0)
        DATA_LABELS_MAP.each do |key, label|
          value = point[key]
          value = value / 10.0 if value && key == "ev"
          @data[label] << value
        end
      end
    end

    def set_extra
      @extra["drink_weight"] = json["samples"].last["ev"]
    end
  end
end
