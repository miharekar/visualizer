module Parsers
  class Beanconqueror < Base
    def parse
      @start_time = Time.at(json.dig("brew", "config", "unix_timestamp").to_i).utc
      @profile_title = json.dig("preparation", "name").presence || "Beanconqueror"
      @brewdata = json
      set_extra
      fake_timeframe
    end

    private

    memo_wise def sha
      Digest::SHA256.base64digest(brewdata["brewFlow"].sort.to_json) if brewdata["brewFlow"].present?
    end

    def existing_shot(user)
      Shot.find_by(id: json["visualizerId"], user:) if json["visualizerId"].present?
    end

    def set_coffee_bag_attributes(shot)
      bean_information = brewdata.dig("bean", "bean_information")&.first
      attributes = {
        country: bean_information&.dig("country"),
        region: bean_information&.dig("region"),
        farm: bean_information&.dig("farm"),
        farmer: bean_information&.dig("farmer"),
        variety: bean_information&.dig("variety"),
        elevation: bean_information&.dig("elevation"),
        processing: bean_information&.dig("processing"),
        harvest_time: bean_information&.dig("harvest_time"),
        quality_score: brewdata.dig("bean", "cupping_points")
      }
      shot.coffee_bag.update(attributes)
    end

    def set_extra
      @extra["bean_brand"] = brewdata.dig("bean", "roaster")
      @extra["bean_type"] = brewdata.dig("bean", "name")
      @extra["roast_level"] = brewdata.dig("bean", "roast")
      @extra["roast_date"] = Date.parse(brewdata.dig("bean", "roastingDate")).strftime("%Y-%m-%d") rescue nil
      @extra["grinder_model"] = brewdata.dig("mill", "name")
      @extra["grinder_setting"] = brewdata.dig("brew", "grind_size")
      @extra["drink_weight"] = brewdata.dig("brew", "brew_beverage_quantity")
      @extra["bean_weight"] = brewdata.dig("brew", "grind_weight")
      @extra["drink_tds"] = brewdata.dig("brew", "tds")
      @extra["drink_ey"] = brewdata.dig("brew", "ey")
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
