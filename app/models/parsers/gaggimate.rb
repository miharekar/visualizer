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
      "ev" => "espresso_flow_weight",
    }.freeze

    def parse
      @start_time = Time.at(json["timestamp"]).utc
      @profile_title = profile_label
      @profile_fields = profile_data
      prepare_data
      set_extra
    end

    private

    def profile_label
      if json["profile"].is_a?(Hash)
        json.dig("profile", "label")
      else
        json["profile"]
      end
    end

    def profile_data
      if json["profile"].is_a?(Hash)
        json["profile"]
      else
        { "label" => json["profile"] }
      end
    end

    def prepare_data
      @timeframe = []
      DATA_LABELS_MAP.each_value { |label| @data[label] = [] }

      # Initialize missing keys that CSV export expects
      @data["espresso_weight"] = []
      @data["espresso_flow_weight"] = []

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
      last_sample = json["samples"].last
      @extra["drink_weight"] = last_sample["ev"] if last_sample && last_sample["ev"]
    end
  end
end
