# frozen_string_literal: true

module ShotProfile
  JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze

  extend ActiveSupport::Concern

  def tcl_profile_fields
    @tcl_profile_fields ||= profile_fields.except("json")
  end

  def json_profile_fields
    @json_profile_fields ||= profile_fields["json"]
  end

  def tcl_profile
    return if tcl_profile_fields.blank?

    content = tcl_profile_fields.to_a.sort_by(&:first).map do |k, v|
      v = "Visualizer/#{v}" if k == "profile_title"
      v = "#{v.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if k == "profile_notes"
      v = "{}" if v.blank?
      v = "{#{v}}" if /\w\s\w/.match?(v)

      "#{k} #{v}"
    end

    file_from_content(["#{shot.profile_title} from Visualizer", ".tcl"], content.join("\n"))
  end

  def json_profile
    return if json_profile_fields.blank?

    json = {}
    JSON_PROFILE_KEYS.each do |key|
      v = profile_fields["json"][key]
      v = "Visualizer/#{v}" if key == "title"
      v = "#{v.gsub("Downloaded from Visualizer", "").strip}\n\nDownloaded from Visualizer" if key == "notes"
      json[key] = v
    end

    JSON.pretty_generate(json)
  end

  private

  def file_from_content(filename, content)
    file = Tempfile.new(filename)
    file.write(content)
    file.close
    file.path
  end
end
