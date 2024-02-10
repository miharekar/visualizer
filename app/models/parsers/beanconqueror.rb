# frozen_string_literal: true

module Parsers
  class Beanconqueror < Base
    def parse
      @start_time = Time.at(file.dig("brew", "config", "unix_timestamp").to_i).utc
      @profile_title = file.dig("preparation", "name").presence || "Beanconqueror"
      @brewdata = file
      extract_bean(file["bean"])
      extract_grinder(file["mill"])
      extract_brew(file["brew"])
      fake_timeframe
    end

    private

    memo_wise def sha
      Digest::SHA256.base64digest(brewdata["brewFlow"].sort.to_json) if brewdata["brewFlow"].present?
    end

    def extract_bean(bean)
      @extra["bean_brand"] = bean["roaster"]
      @extra["bean_type"] = bean["name"]
      @extra["roast_level"] = bean["roast"]
      @extra["roast_date"] = Date.parse(bean["roastingDate"]).strftime("%Y-%m-%d") rescue nil
    end

    def extract_brew(brew)
      @extra["grinder_setting"] = brew["grind_size"]
      @extra["drink_weight"] = brew["brew_beverage_quantity"]
      @extra["bean_weight"] = brew["grind_weight"]
    end

    def extract_grinder(mill)
      @extra["grinder_model"] = mill["name"]
    end

    def fake_timeframe
      @timeframe = [extremes.map(&:last).max - extremes.map(&:first).min]
    end

    memo_wise def extremes
      brewdata["brewFlow"].filter_map do |_, values|
        next if values.empty?

        [values.first, values.last].map { |v| Time.strptime(v["timestamp"], "%H:%M:%S.%L") }
      end
    end
  end
end
