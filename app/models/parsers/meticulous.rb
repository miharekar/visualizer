module Parsers
  class Meticulous < Base
    DATA_LABELS_MAP = {
      "pressure" => "espresso_pressure",
      "flow" => "espresso_flow",
      "weight" => "espresso_weight",
      "gravimetric_flow" => "espresso_flow_weight"
    }.freeze

    def parse
      @start_time = Time.at(json["time"]).utc
      @profile_title = json["profile_name"]
      @profile_fields = json["profile"] || {}
      prepare_data
      set_extra
    end

    private

    def prepare_data
      @timeframe = []
      all_labels = DATA_LABELS_MAP.values + %w[espresso_pressure_goal espresso_flow_goal espresso_temperature_mix espresso_state_change]
      all_labels.each { |label| @data[label] = [] }

      json["data"].each do |point|
        @timeframe << (point["time"] / 1000.0)

        shot = point["shot"] || {}
        DATA_LABELS_MAP.each do |key, label|
          @data[label] << shot[key]
        end

        setpoints = shot["setpoints"] || {}
        @data["espresso_pressure_goal"] << setpoints["pressure"]
        @data["espresso_flow_goal"] << setpoints["flow"]

        sensors = point["sensors"] || {}
        @data["espresso_temperature_mix"] << sensors["tube"]

        @data["espresso_state_change"] << point["status"]
      end
    end

    def set_extra
      last_point = json["data"].last
      @extra["drink_weight"] = last_point&.dig("shot", "weight")
    end
  end
end
