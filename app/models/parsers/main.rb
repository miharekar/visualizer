# frozen_string_literal: true

module Parsers
  class Main
    PROFILE_FIELDS = %w[advanced_shot author beverage_type espresso_decline_time espresso_hold_time espresso_pressure espresso_temperature espresso_temperature_0 espresso_temperature_1 espresso_temperature_2 espresso_temperature_3 espresso_temperature_steps_enabled final_desired_shot_volume final_desired_shot_volume_advanced final_desired_shot_volume_advanced_count_start final_desired_shot_weight final_desired_shot_weight_advanced flow_profile_decline flow_profile_decline_time flow_profile_hold flow_profile_hold_time flow_profile_minimum_pressure flow_profile_preinfusion flow_profile_preinfusion_time maximum_flow maximum_flow_range maximum_flow_range_advanced maximum_flow_range_default maximum_pressure maximum_pressure_range maximum_pressure_range_advanced maximum_pressure_range_default original_profile_title preinfusion_flow_rate preinfusion_guarantee preinfusion_stop_pressure preinfusion_time pressure_end profile_filename profile_language profile_notes profile_title profile_to_save settings_profile_type tank_desired_water_temperature].freeze
    EXTRA_DATA_CAPTURE = (Shot::EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight enable_fahrenheit my_name skin]).freeze

    attr_reader :file, :start_time, :data, :extra, :timeframe, :profile_title, :profile_fields

    def initialize(file)
      @file = file
      @data = {}
      @extra = {}
      @profile_fields = {}
    end

    def sha
      Digest::SHA256.base64digest(data.sort.to_json) if data.present?
    end

    def self.parse(file)
      parser = if file.start_with?("{")
        DecentJson.new(file)
      else
        DecentTcl.new(file)
      end
      parser.parse
      parser
    rescue SystemStackError, StandardError => e
      raise e unless Rails.env.production?

      Sentry.capture_exception(e, extra: {file: @file})
    end
  end
end
