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
      "vf" => "espresso_flow_weight"
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
        point["v"] = point["ev"] if point["v"] == 0 # Fill measured weight with estimated weight if no scale was connected
        point["vf"] = point["pf"] if point["vf"] == 0 # Fill measured flow with estimated flow if no scale was connected
        DATA_LABELS_MAP.each do |key, label|
          value = point[key]
          @data[label] << value
        end
      end
    end

    def set_extra
      @extra["drink_weight"] = json["samples"].last["v"]
    end
  end
end
