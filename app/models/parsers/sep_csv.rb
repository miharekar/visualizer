# frozen_string_literal: true

require "csv"

module Parsers
  class SepCsv < Base
    DATA_LABELS_MAP = {
      weight: "espresso_weight",
      pressure: "espresso_pressure",
      flow_weight: "espresso_flow_weight",
      temperature_mix: "espresso_temperature_mix"
    }.freeze
    MAPPING = {
      "Roastery" => "bean_brand",
      "Beans" => "bean_type",
      "Description" => "bean_notes",
      "Roast Color" => "roast_level",
      "Operator" => "my_name",
      "Grinder Brand" => "grinder_model",
      "Grinder Model" => "grinder_model",
      "Grinder Setting" => "grinder_setting",
      "Dose" => "bean_weight",
      "Weight" => "drink_weight",
      "Tds" => "drink_tds"
    }.freeze

    def initialize(file)
      super
      @datapoints = {weight: {}, pressure: {}, temperature_mix: {}}
    end

    def parse
      csv = CSV.parse(file, headers: true)
      csv.each do |row|
        if row["information_type"] == "meta"
          parse_extra(row)
        elsif row["information_type"] == "moment"
          parse_data(row)
        end
      end
      prepare_data
    end

    private

    def parse_extra(row)
      return if row["metadata"].blank?

      if MAPPING[row["metatype"]]
        value = [@extra[MAPPING[row["metatype"]]], row["metadata"]].compact.join(" ")
        @extra[MAPPING[row["metatype"]]] = value.strip
      elsif row["metatype"] == "Name"
        @profile_title = row["metadata"]
      elsif row["metatype"] == "Date"
        @start_time = Time.parse(row["metadata"]).utc
      elsif row["metatype"] == "Roasting Date"
        @extra["roast_date"] = Date.parse(row["metadata"]).strftime("%Y-%m-%d")
      else
        value = [@extra["espresso_notes"], "#{row["metatype"]}: #{row["metadata"]}"].compact.join("\n")
        @extra["espresso_notes"] = value
      end
    end

    def parse_data(row)
      if row["comment"] == "sample: weight" && row["current_total_shot_weight"].present?
        @datapoints[:weight][row["elapsed"].to_f] = row["current_total_shot_weight"].to_f
      elsif row["comment"] == "sample: pressure" && row["pressure"].present?
        @datapoints[:pressure][row["elapsed"].to_f] = row["pressure"].to_f
      elsif row["comment"] == "sample: temperature" && row["water_temperature_in"].present?
        @datapoints[:temperature_mix][row["elapsed"].to_f] = row["water_temperature_in"].to_f
      end
    end

    def prepare_data
      calculate_weight_flow
      @timeframe = []
      @datapoints = @datapoints.compact_blank
      relevant_keys = @datapoints.keys
      labels_map = DATA_LABELS_MAP.values_at(*relevant_keys)
      @data = labels_map.index_with { |label| [] }
      most_data = @datapoints.max_by { |_k, v| v.size }.first
      time_step = (@datapoints[most_data].keys.last - @datapoints[most_data].keys.first) / @datapoints[most_data].keys.size
      first_timestamp = @datapoints.min_by { |_k, v| v.keys.first }[1].keys.first
      last_timestamp = @datapoints.max_by { |_k, v| v.keys.last }[1].keys.last
      sorted_points = @datapoints.transform_values { |v| v.sort_by { |k, _v| k }.to_a }
      first_timestamp.step(last_timestamp, time_step).each do |time|
        @timeframe << time
        sorted_points.each do |key, points|
          label = DATA_LABELS_MAP[key]
          value = closest_bsearch(points, time)[1]
          @data[label] << (value.positive? ? value : 0)
        end
      end
    end

    def calculate_weight_flow
      return if @datapoints[:weight].blank?

      @datapoints[:flow_weight] = {}
      previous = []
      @datapoints[:weight].each do |time, weight|
        previous = previous.drop_while { |t, _| t < time - 1.0 }
        @datapoints[:flow_weight][time] = [weight - previous.first[1], 0].max.round(2) if previous.any?
        previous << [time, weight]
      end
    end
  end
end
