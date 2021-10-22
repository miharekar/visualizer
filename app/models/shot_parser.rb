# frozen_string_literal: true

class ShotParser
  PROFILE_FIELDS = %w[advanced_shot author beverage_type espresso_decline_time espresso_hold_time espresso_pressure espresso_temperature espresso_temperature_0 espresso_temperature_1 espresso_temperature_2 espresso_temperature_3 espresso_temperature_steps_enabled final_desired_shot_volume final_desired_shot_volume_advanced final_desired_shot_volume_advanced_count_start final_desired_shot_weight final_desired_shot_weight_advanced flow_profile_decline flow_profile_decline_time flow_profile_hold flow_profile_hold_time flow_profile_minimum_pressure flow_profile_preinfusion flow_profile_preinfusion_time maximum_flow maximum_flow_range maximum_flow_range_advanced maximum_flow_range_default maximum_pressure maximum_pressure_range maximum_pressure_range_advanced maximum_pressure_range_default original_profile_title preinfusion_flow_rate preinfusion_guarantee preinfusion_stop_pressure preinfusion_time pressure_end profile_filename profile_language profile_notes profile_title profile_to_save settings_profile_type tank_desired_water_temperature].freeze
  EXTRA_DATA_CAPTURE = (Shot::EXTRA_DATA_METHODS + %w[bean_weight DSx_bean_weight grinder_dose_weight enable_fahrenheit]).freeze
  JSON_MAPPING = {
    "_weight" => "by_weight",
    "_weight_raw" => "by_weight_raw",
    "_goal" => "goal"
  }.freeze

  attr_reader :start_time, :data, :extra, :timeframe, :profile_title, :profile_fields, :sha

  def initialize(file)
    @file = file
    @data = {}
    @extra = {}
    @profile_fields = {}
    @start_chars_to_ignore = %i[c b]
    parse_file

    @sha = Digest::SHA256.base64digest(data.sort.to_json) if data.present?
  end

  private

  def parse_file
    json_parse || tcl_parse
  rescue Tickly::Parser::Error => e
    invalid_machine = @file.split("machine {")
    raise e unless invalid_machine.size > 1

    @file = invalid_machine.first
    retry
  rescue SystemStackError, StandardError => e
    raise e if Rails.env.development?

    Rollbar.error(e, file: @file)
  end

  def json_parse
    parsed = JSON.parse(@file)

    extract_clock(parsed["timestamp"])
    extract_espresso_elapsed(parsed["elapsed"])
    @profile_fields["json"] = parsed["profile"]
    @profile_title = parsed["profile"]["title"]

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
    false
  end

  def tcl_parse
    parsed = Tickly::Parser.new.parse(@file)
    parsed.each do |name, data|
      extract_data_from(name, data)
      next unless name == "settings"

      data.each do |setting_name, setting_data|
        next if @start_chars_to_ignore.include?(setting_name)

        extract_data_from("setting_#{setting_name.strip}", setting_data)
      end
    end
    @profile_title = @profile_fields["profile_title"]
  end

  def extract_data_from(name, data)
    return if data.blank?

    method = "extract_#{name}"
    data = @start_chars_to_ignore.include?(data.first) ? data[1..] : data
    __send__(method, data) if respond_to?(method, true)
  end

  def extract_clock(data)
    @start_time = Time.at(data.to_i).utc
  end

  def extract_espresso_elapsed(data)
    @timeframe = data
  end

  def extract_profile(data)
    stop = "#{data.last.join(' ')}\n}"
    @profile_fields["json"] = JSON.parse(@file[/profile (\{(.*)#{stop})/m, 1])
  rescue StandardError
    nil
  end

  Shot::DATA_LABELS.each do |name|
    define_method("extract_#{name}") do |data|
      @data[name] = data
    end
  end

  EXTRA_DATA_CAPTURE.each do |name|
    define_method("extract_setting_#{name}") do |data|
      @extra[name] = handle_tcl_array(data).force_encoding("UTF-8")
    end
  end

  PROFILE_FIELDS.each do |name|
    define_method("extract_setting_#{name}") do |data|
      @profile_fields[name] = handle_tcl_array(data).force_encoding("UTF-8")
    end
  end

  def handle_tcl_array(data)
    return data unless data.is_a?(Array)

    data.map do |line|
      next line unless line.is_a?(Array)

      line = line.map do |item|
        item.is_a?(Array) ? handle_tcl_array([item]) : item
      end

      if line.first == :b
        line.shift
        line.first.prepend("[")
        line.last.concat("]")
      end

      if line.first == :c
        line.shift
        line.first.prepend("{")
        line.last.concat("}")
      end

      line.join(" ")
    end.join(" ")
  end
end
