module Parsers
  class Gaggimate < Base
    DATA_LABELS_MAP = {
      "cp" => "espresso_pressure",
      "fl" => "espresso_flow",
      "tp" => "espresso_pressure_goal",
      "tf" => "espresso_flow_goal",
      "tt" => "espresso_temperature_goal",
      "ct" => "espresso_temperature_mix"
    }
    EXTRA_LABELS = %w[espresso_weight espresso_flow_weight]

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
      (DATA_LABELS_MAP.values + EXTRA_LABELS).each { |label| @data[label] = [] }

      has_scale = json["samples"].any? { |point| point["v"].to_i != 0 }
      measured_flow = json["samples"].any? { |point| point["vf"].to_i != 0 }
      json["samples"].each do |point|
        @timeframe << (point["t"] / 1000.0)
        DATA_LABELS_MAP.each { |key, label| @data[label] << point[key] }
        @data["espresso_weight"] << (has_scale ? point["v"] : point["ev"])
        @data["espresso_flow_weight"] << (measured_flow ? point["vf"] : point["pf"])
      end
    end

    def set_extra
      @extra["drink_weight"] = @data["espresso_weight"].last
    end
  end
end
