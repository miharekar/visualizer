# frozen_string_literal: true

module Parsers
  class DecentJson < Main
    JSON_MAPPING = {"_weight" => "by_weight", "_weight_raw" => "by_weight_raw", "_goal" => "goal"}.freeze

    def parse
      @start_time = Time.at(file["timestamp"].to_i).utc
      @timeframe = file["elapsed"]
      @profile_fields["json"] = file["profile"]
      @profile_title = file.dig("profile", "title")

      %w[pressure flow].each do |key|
        @data["espresso_#{key}"] = file.dig(key, key)

        JSON_MAPPING.each do |suffix, subkey|
          value = file.dig(key, subkey)
          next if value.blank?

          @data["espresso_#{key}#{suffix}"] = value
        end
      end

      %w[basket mix goal].each do |key|
        @data["espresso_temperature_#{key}"] = file.dig("temperature", key)
      end

      %w[weight water_dispensed].each do |key|
        @data["espresso_#{key}"] = file.dig("totals", key)
      end

      @data["espresso_state_change"] = file["state_change"]

      settings = file.dig("app", "data", "settings")
      EXTRA_DATA_CAPTURE.each do |key|
        @extra[key] = settings[key]
      end

      PROFILE_FIELDS.each do |key|
        @profile_fields[key] = settings[key]
      end
    end
  end
end
