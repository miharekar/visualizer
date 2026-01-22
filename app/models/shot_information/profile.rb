require "csv"

class ShotInformation
  module Profile
    prepend MemoWise

    JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
    CSV_PROFILE_HEADERS = %w[information_type elapsed pressure current_total_shot_weight flow_in flow_out water_temperature_boiler water_temperature_in water_temperature_basket metatype metadata comment].freeze

    def has_profile?
      tcl_profile_fields.present? || profile_fields.present?
    end

    memo_wise def tcl_profile_fields
      tcl_profile_fields = profile_fields.except("json")
      return if tcl_profile_fields.blank?
      return unless %w[profile_notes advanced_shot].all? { tcl_profile_fields.key?(it) }

      tcl_profile_fields
    end

    def tcl_profile
      return if tcl_profile_fields.blank?

      tcl_profile_fields.to_a.sort_by(&:first).map do |k, v|
        v = "#{v.to_s.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if k == "profile_notes"
        v = "{}" if v.blank?
        v = "{#{v}}" if /\w\s\w/.match?(v)

        "#{k} #{v}"
      end.join("\n")
    end

    def json_profile
      if profile_fields.key?("json")
        json = {}
        JSON_PROFILE_KEYS.each do |key|
          v = profile_fields["json"][key]
          v = "#{v.to_s.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if key == "notes"
          json[key] = v
        end
      else
        json = profile_fields
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
          metadata_value = extra[value]
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
  end
end
