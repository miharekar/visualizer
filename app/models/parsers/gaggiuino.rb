module Parsers
  class Gaggiuino < Base
    DATA_LABELS_MAP = {
      "pressure" => "espresso_pressure",
      "pumpFlow" => "espresso_flow",
      "shotWeight" => "espresso_weight",
      "targetPressure" => "espresso_pressure_goal",
      "targetPumpFlow" => "espresso_flow_goal",
      "targetTemperature" => "espresso_temperature_goal",
      "temperature" => "espresso_temperature_mix",
      "waterPumped" => "espresso_water_dispensed",
      "weightFlow" => "espresso_flow_weight"
    }.freeze

    def parse
      @start_time = Time.at(json["timestamp"]).utc
      @profile_title = json.dig("profile", "name")
      @profile_fields = json["profile"]
      prepare_data
      set_extra
    end

    private

    def prepare_data
      @timeframe = []
      DATA_LABELS_MAP.each_value { |label| @data[label] = [] }

      json["datapoints"].each do |point|
        @timeframe << (point["timeInShot"] / 1000.0)
        DATA_LABELS_MAP.each do |key, label|
          value = point[key]
          value = value / 10.0 if key == "waterPumped"
          @data[label] << value
        end
      end
    end

    def set_extra
      @extra["drink_weight"] = json["datapoints"].last["shotWeight"]
    end
  end
end
