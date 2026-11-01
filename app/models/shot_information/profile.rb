require "csv"

class ShotInformation
  module Profile
    prepend MemoWise

    JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
    TCL_ESCAPES = {"\n" => "\\n", "\t" => "\\t", "\r" => "\\r"}.freeze
    CSV_PROFILE_HEADERS = %w[information_type elapsed pressure current_total_shot_weight flow_in flow_out water_temperature_boiler water_temperature_in water_temperature_basket metatype metadata comment].freeze

    LEGACY_PROFILE_DEFAULTS = {
      "settings_profile_type" => "settings_2c", "espresso_hold_time" => 15, "preinfusion_time" => 20, "espresso_pressure" => 6.0, "espresso_decline_time" => 30, "pressure_end" => 4.0,
      "flow_profile_preinfusion" => 4, "flow_profile_preinfusion_time" => 5, "flow_profile_hold" => 2, "flow_profile_hold_time" => 8, "flow_profile_decline" => 1.2, "flow_profile_decline_time" => 17,
      "flow_profile_minimum_pressure" => 4, "preinfusion_flow_rate" => 4, "preinfusion_stop_pressure" => 4.0, "final_desired_shot_volume" => 42, "final_desired_shot_weight" => 42,
      "maximum_pressure" => 0, "maximum_flow" => 0, "maximum_pressure_range_advanced" => 0.6, "maximum_flow_range_advanced" => 0.6, "maximum_pressure_range_default" => 0.9,
      "maximum_flow_range_default" => 1.0, "espresso_temperature_steps_enabled" => 0
    }.freeze
    LEGACY_STEP_NUMBERS = %w[temperature pressure flow seconds volume weight].freeze
    LEGACY_STEP_EXTRAS = %w[pump_mode power mode_max_pressure lever_spring lever_give reserved].freeze
    LEGACY_EXIT_DEFAULTS = {"exit_pressure_over" => 0, "exit_pressure_under" => 0, "exit_flow_over" => 0, "exit_flow_under" => 0}.freeze
    LEGACY_EXIT_TYPES = %w[pressure flow power].freeze
    LEGACY_EXIT_CONDITIONS = %w[over under].freeze

    def has_profile?
      stored_profile_values? || json_steps.present?
    end

    memo_wise def tcl_profile_fields
      tcl_profile_fields = profile_fields.except("json")

      if json_steps.present? && (tcl_profile_fields["advanced_shot"].nil? || !stored_profile_values?)
        legacy_fields_from_json
      elsif stored_profile_values? && %w[profile_notes advanced_shot].all? { tcl_profile_fields.key?(it) }
        tcl_profile_fields
      end
    end

    def tcl_profile
      return if tcl_profile_fields.blank?

      tcl_profile_fields.to_a.sort_by(&:first).map do |k, v|
        v = "#{v.to_s.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if k == "profile_notes"
        "#{k} #{tcl_element(v)}"
      end.join("\n")
    end

    def json_profile
      if profile_fields["json"].is_a?(Hash)
        json = {}
        JSON_PROFILE_KEYS.each do |key|
          v = profile_fields["json"][key]
          v = "#{v.to_s.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if key == "notes"
          json[key] = v
        end
      else
        json = profile_fields.except("json")
      end
      JSON.pretty_generate(json)
    end

    def csv_profile
      CSV.generate do |csv|
        csv << CSV_PROFILE_HEADERS

        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Name", shot.profile_title, "text"]
        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Date", shot.start_time.iso8601, "ISO8601 formatted date"]
        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Roasting Date", shot.iso8601_roast_date_time, "ISO8601 formatted date"] if shot.iso8601_roast_date_time

        Parsers::SepCsv::MAPPING.each do |key, value|
          metadata_value = value == "bean_notes" ? shot[:bean_notes] : extra[value]
          next if metadata_value.blank?

          csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, key, metadata_value, "text"]
        end

        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Attribution", "Visualizer", nil]
        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Software", "Visualizer", nil]
        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Url", "https://visualizer.coffee/shots/#{shot.id}", nil]
        csv << ["meta", nil, nil, nil, nil, nil, nil, nil, nil, "Export version", "1.0.0", nil]

        timeframe.each.with_index do |time, i|
          csv << ["moment", time.to_f.round(5), data_point("espresso_pressure", i), data_point("espresso_weight", i), data_point("espresso_flow", i), data_point("espresso_flow_weight", i), nil, data_point("espresso_temperature_mix", i), data_point("espresso_temperature_basket", i), nil, nil, "Visualizer"]
        end
      end
    end

    def data_point(key, index)
      data[key][index].to_f.round(5) if data[key].respond_to?(:[])
    end

    private

    def stored_profile_values?
      profile_fields.except("json").compact_blank.present?
    end

    def json_steps
      steps = profile_fields["json"]["steps"] if profile_fields["json"].is_a?(Hash)
      steps if steps.is_a?(Array) && steps.all?(Hash)
    end

    def legacy_fields_from_json
      json = profile_fields["json"]
      temperature = json_steps.first["temperature"].presence || 0

      fields = LEGACY_PROFILE_DEFAULTS.merge(
        "profile_title" => json["title"],
        "author" => json["author"],
        "profile_notes" => json["notes"],
        "beverage_type" => json["beverage_type"].presence || "espresso",
        "profile_language" => json["lang"].presence || "en",
        "tank_desired_water_temperature" => json["tank_temperature"].presence || 0,
        "final_desired_shot_weight_advanced" => json["target_weight"].presence || 0,
        "final_desired_shot_volume_advanced" => json["target_volume"].presence || 0,
        "final_desired_shot_volume_advanced_count_start" => json["target_volume_count_start"].presence || 0,
        "espresso_temperature" => temperature,
        "advanced_shot" => json_steps.map { tcl_element(legacy_step(it)) }.join(" ")
      )
      4.times { fields["espresso_temperature_#{it}"] = temperature }
      fields["profile_filename"] = json["reference_file"] if json["reference_file"].present?
      fields
    end

    def legacy_step(step)
      legacy = {"name" => step["name"], "sensor" => step["sensor"].presence || "coffee", "pump" => step["pump"].presence || "pressure", "transition" => step["transition"].presence || "fast"}
      LEGACY_STEP_NUMBERS.each { legacy[it] = step[it].presence || 0 }
      legacy.merge!(legacy_exit(step["exit"]), legacy_limiter(step["limiter"]), step.slice(*LEGACY_STEP_EXTRAS).compact_blank)
      legacy.map { |key, value| "#{key} #{tcl_element(value)}" }.join(" ")
    end

    def legacy_exit(exit)
      if exit.is_a?(Hash) && LEGACY_EXIT_TYPES.include?(exit["type"]) && LEGACY_EXIT_CONDITIONS.include?(exit["condition"])
        key = "#{exit["type"]}_#{exit["condition"]}"
        LEGACY_EXIT_DEFAULTS.merge("exit_if" => 1, "exit_type" => key, "exit_#{key}" => exit["value"].presence || 0)
      else
        LEGACY_EXIT_DEFAULTS.merge("exit_if" => 0)
      end
    end

    def legacy_limiter(limiter)
      if limiter.is_a?(Hash)
        {"max_flow_or_pressure" => limiter["value"].presence || 0, "max_flow_or_pressure_range" => limiter["range"].presence || 0.6}
      else
        {"max_flow_or_pressure" => 0, "max_flow_or_pressure_range" => 0.6}
      end
    end

    def tcl_element(value)
      value = value.blank? ? "" : value.to_s

      if value.blank?
        "{}"
      elsif !tcl_braceable?(value)
        value.gsub(/[\\{}\[\]$";\s]/) { |char| TCL_ESCAPES.fetch(char, "\\#{char}") }
      elsif /[\s\\]/.match?(value) || value.start_with?("{", '"')
        "{#{value}}"
      else
        value
      end
    end

    def tcl_braceable?(value)
      return false if /\A(?:[^\\]|\\.)*\\\z/m.match?(value)

      depth = 0
      value.scan(/\\.|[{}]/m) do |token|
        depth += 1 if token == "{"
        depth -= 1 if token == "}"
        return false if depth.negative?
      end
      depth.zero?
    end
  end
end
