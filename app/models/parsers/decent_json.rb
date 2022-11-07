# frozen_string_literal: true

module Parsers
  class DecentJson < Main
    JSON_MAPPING = {"_weight" => "by_weight", "_weight_raw" => "by_weight_raw", "_goal" => "goal"}.freeze

    def parse
      parsed = JSON.parse(file)

      @start_time = Time.at(parsed["timestamp"].to_i).utc
      @timeframe = parsed["elapsed"]
      @profile_fields["json"] = parsed["profile"]
      @profile_title = parsed.dig("profile", "title")

      %w[pressure flow resistance].each do |key|
        @data["espresso_#{key}"] = parsed.dig(key, key)

        JSON_MAPPING.each do |suffix, subkey|
          value = parsed.dig(key, subkey)
          next if value.blank?

          @data["espresso_#{key}#{suffix}"] = value
        end
      end

      %w[basket mix goal].each do |key|
        @data["espresso_temperature_#{key}"] = parsed.dig("temperature", key)
      end

      %w[weight water_dispensed].each do |key|
        @data["espresso_#{key}"] = parsed.dig("totals", key)
      end

      @data["espresso_state_change"] = parsed["state_change"]

      settings = parsed.dig("app", "data", "settings")
      EXTRA_DATA_CAPTURE.each do |key|
        @extra[key] = settings[key]
      end

      PROFILE_FIELDS.each do |key|
        @profile_fields[key] = settings[key]
      end
    rescue JSON::ParserError, TypeError
    end
  end
end
