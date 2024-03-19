# frozen_string_literal: true

module Parsers
  class DecentJson < Base
    JSON_MAPPING = {"_weight" => "by_weight", "_weight_raw" => "by_weight_raw", "_goal" => "goal"}.freeze

    def parse
      @start_time = Time.at(json["timestamp"].to_i).utc
      @timeframe = json["elapsed"]
      @profile_fields["json"] = json["profile"]
      @profile_title = json.dig("profile", "title")

      %w[pressure flow].each do |key|
        @data["espresso_#{key}"] = json.dig(key, key)

        JSON_MAPPING.each do |suffix, subkey|
          value = json.dig(key, subkey)
          next if value.blank?

          @data["espresso_#{key}#{suffix}"] = value
        end
      end

      %w[basket mix goal].each do |key|
        @data["espresso_temperature_#{key}"] = json.dig("temperature", key)
      end

      %w[weight water_dispensed].each do |key|
        @data["espresso_#{key}"] = json.dig("totals", key)
      end

      @data["espresso_state_change"] = json["state_change"]

      settings = json.dig("app", "data", "settings")
      EXTRA_DATA_CAPTURE.each do |key|
        @extra[key] = settings[key]
      end

      PROFILE_FIELDS.each do |key|
        @profile_fields[key] = settings[key]
      end
    end
  end
end
