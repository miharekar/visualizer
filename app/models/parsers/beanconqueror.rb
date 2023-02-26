# frozen_string_literal: true

module Parsers
  class Beanconqueror < Main
    def parse
      @start_time = Time.at(file.dig("brew", "config", "unix_timestamp").to_i).utc
      extract_bean(file["bean"])
      extract_mill(file["mill"])
      extract_brew(file["brew"])
      extract_preparation(file["preparation"])
      extract_water(file["water"])

      @data["espresso_weight"] = extract_weight(file["brewFlow"]["weight"])
      start = Time.parse(file["brewFlow"]["weight"].first["timestamp"]).to_f
      @timeframe = file["brewFlow"]["weight"].map { |w| (Time.parse(w["timestamp"]).to_f - start).round(4).to_s }
    end

    private

    def extract_bean(bean)
      @extra["bean_brand"] = bean.delete("roaster")
      @extra["bean_type"] = bean.delete("name")
      @extra["bean_weight"] = bean.delete("weight")
      @extra["roast_level"] = bean.delete("roast")
      @extra["roast_date"] = bean.delete("roastingDate")
      @extra["bean_notes"] = "```javascript\n#{JSON.pretty_generate(bean)}\n```"
    end

    def extract_brew(brew)
      @extra["grinder_setting"] = brew.delete("grind_size")
      @extra["drink_weight"] = brew.delete("brew_quantity")
      @extra["espresso_notes"] = "#### Brew:\n\n#{brew.delete("note")}\n\n```javascript\n#{JSON.pretty_generate(brew.except("config"))}\n```\n\n"
    end

    def extract_mill(mill)
      @extra["grinder_model"] = mill.delete("name")
    end

    def extract_preparation(preparation)
      @extra["espresso_notes"] += "#### Preparation:\n\n```javascript\n#{JSON.pretty_generate(preparation)}\n```\n\n"
    end

    def extract_water(water)
      @extra["espresso_notes"] += "#### Water:\n\n```javascript\n#{JSON.pretty_generate(water)}\n```\n\n"
    end

    def extract_weight(weight)
      weight.map { |w| w["actual_weight"].to_f }
    end
  end
end
