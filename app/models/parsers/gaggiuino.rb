module Parsers
  class Gaggiuino < Base
    THIS_CENTURY = Time.utc(2000, 1, 1).to_i

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
      @start_time = parse_start_time
      @profile_title = json.dig("profile", "name")
      @profile_fields = json["profile"]
      prepare_data
      set_extra
    end

    private

    def parse_start_time
      timestamp = json["timestamp"].to_f
      return Time.at(timestamp).utc if timestamp > THIS_CENTURY

      Time.current.utc
    end

    def prepare_data
      @timeframe = []
      DATA_LABELS_MAP.each_value { |label| @data[label] = [] }

      json["datapoints"].each do |point|
        @timeframe << (point["timeInShot"] / 1000.0)
        DATA_LABELS_MAP.each do |key, label|
          value = point[key]
          value = value / 10.0 if value && key == "waterPumped"
          @data[label] << value
        end
      end
    end

    def set_extra
      @extra["drink_weight"] = json["datapoints"].last["shotWeight"]
    end
  end
end
