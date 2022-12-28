# frozen_string_literal: true

require "csv"

module Parsers
  class SepCsv < Main
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
      @weight = {}
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
      calculate_weight_flow
      @timeframe = @weight.keys.map(&:to_s)
      @data["espresso_weight"] = @weight.values.map(&:to_s)
    end

    private

    def parse_extra(row)
      return if row["metadata"].blank?

      if MAPPING[row["metatype"]]
        value = [@extra[MAPPING[row["metatype"]]], row["metadata"]].compact.join(" ")
        @extra[MAPPING[row["metatype"]]] = value
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
      return if row["current_total_shot_weight"].blank?

      @weight[row["elapsed"].to_f] = row["current_total_shot_weight"].to_f
    end

    def calculate_weight_flow
      @data["espresso_flow_weight"] = []
      @weight.each do |time, weight|
        previous = @weight.find { |t, w| t >= time - 1.0 }
        @data["espresso_flow_weight"] << [weight - previous[1], 0].max.round(2)
      end
    end
  end
end
