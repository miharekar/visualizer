module Parsers
  # Parser for Meticulous espresso machine shot files (.shot.json).
  #
  # Meticulous JSON format contains:
  # - time: Unix timestamp of shot start
  # - profile_name: Name of the brewing profile
  # - data: Array of time-series data points with shot metrics and sensor readings
  #
  # Each data point includes:
  # - shot: pressure, flow, weight, gravimetric_flow, and setpoints
  # - sensors: temperature readings (tube, bar_up, bar_mid_up, bar_mid_down, bar_down)
  # - status: Current stage name (e.g., "Prefill", "Extraction")
  # - time: Milliseconds since shot start
  class Meticulous < Base
    # Maps Meticulous shot data keys to standard visualizer data labels.
    DATA_LABELS_MAP = {
      "pressure" => "espresso_pressure",
      "flow" => "espresso_flow",
      "weight" => "espresso_weight",
      "gravimetric_flow" => "espresso_flow_weight"
    }.freeze

    # Parses the Meticulous JSON data and populates shot attributes.
    # Sets start_time, profile_title, profile_fields, and delegates to
    # prepare_data and set_extra for time-series and metadata extraction.
    def parse
      @start_time = Time.at(json["time"]).utc
      @profile_title = json["profile_name"]
      @profile_fields = json["profile"] || {}
      prepare_data
      set_extra
    end

    private

    # Extracts time-series data from Meticulous JSON format.
    # Converts time from milliseconds to seconds and maps shot/sensor data
    # to standard visualizer labels. Also captures status for stage detection.
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

    # Sets extra metadata from the shot data.
    # Extracts the final drink weight from the last data point.
    def set_extra
      last_point = json["data"].last
      @extra["drink_weight"] = last_point&.dig("shot", "weight")
    end
  end
end
