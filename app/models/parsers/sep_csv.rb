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
    MAX_DATAPOINTS = 20_000

    def initialize(file)
      super
      @datapoints = {weight: {}, pressure: {}, temperature_mix: {}}
    end

    def parse
      headers, *rows = CSV.parse(file)
      @columns = {}
      headers&.each_with_index { |name, index| @columns[name] ||= index }
      rows.each do |row|
        type = field(row, "information_type")
        if type == "meta"
          parse_extra(row)
        elsif type == "moment"
          parse_data(row)
        end
      end
      prepare_data
    end

    private

    def field(row, name)
      index = @columns[name]
      row[index] if index
    end

    def parse_extra(row)
      metadata = field(row, "metadata")
      return if metadata.blank?

      metatype = field(row, "metatype")
      if MAPPING[metatype]
        value = [@extra[MAPPING[metatype]], metadata].compact.join(" ")
        @extra[MAPPING[metatype]] = value.strip
      elsif metatype == "Name"
        @profile_title = metadata
      elsif metatype == "Date"
        @start_time = Time.zone.iso8601(metadata)
      elsif metatype == "Roasting Date"
        @extra["roast_date"] = metadata
      else
        value = [@extra["espresso_notes"], "#{metatype}: #{metadata}"].compact.join("\n")
        @extra["espresso_notes"] = value
      end
    end

    def note_html(_attribute, value)
      RichTextSanitizer.from_plain_text(value)
    end

    def parse_data(row)
      comment = field(row, "comment")
      if comment == "sample: weight" && field(row, "current_total_shot_weight").present?
        @datapoints[:weight][field(row, "elapsed").to_f] = field(row, "current_total_shot_weight").to_f
      elsif comment == "sample: pressure" && field(row, "pressure").present?
        @datapoints[:pressure][field(row, "elapsed").to_f] = field(row, "pressure").to_f
      elsif comment == "sample: temperature" && field(row, "water_temperature_in").present?
        @datapoints[:temperature_mix][field(row, "elapsed").to_f] = field(row, "water_temperature_in").to_f
      end
    end

    def prepare_data
      calculate_weight_flow
      @timeframe = []
      @datapoints = @datapoints.compact_blank
      relevant_keys = @datapoints.keys
      labels_map = DATA_LABELS_MAP.values_at(*relevant_keys)
      @data = labels_map.index_with { |_label| [] }
      most_data = @datapoints.max_by { |_k, v| v.size }.first
      time_step = (@datapoints[most_data].keys.last - @datapoints[most_data].keys.first) / @datapoints[most_data].keys.size
      first_timestamp = @datapoints.min_by { |_k, v| v.keys.first }[1].keys.first
      last_timestamp = @datapoints.max_by { |_k, v| v.keys.last }[1].keys.last
      raise InvalidFile, "Too many datapoints" unless ((last_timestamp - first_timestamp) / time_step).between?(0, MAX_DATAPOINTS)

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
