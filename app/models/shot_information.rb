# frozen_string_literal: true

class ShotInformation < ApplicationRecord
  include Bsearch

  JSON_PROFILE_KEYS = %w[title author notes beverage_type steps tank_temperature target_weight target_volume target_volume_count_start legacy_profile_type type lang hidden reference_file changes_since_last_espresso version].freeze
  DATA_LABELS_MAP = {"weight" => "espresso_weight", "waterFlow" => "espresso_flow", "realtimeFlow" => "espresso_flow_weight", "pressureFlow" => "espresso_pressure", "temperatureFlow" => "espresso_temperature_mix"}.freeze
  DATA_VALUES_MAP = {"weight" => "actual_weight", "waterFlow" => "value", "realtimeFlow" => "flow_value", "pressureFlow" => "actual_pressure", "temperatureFlow" => "actual_temperature"}.freeze

  belongs_to :shot

  def extra
    super.presence || {}
  end

  def profile_fields
    super.presence || {}
  end

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

  belongs_to :shot

  attr_reader :new_data, :new_timeframe

  def parse_brew_flow
    brew_flow = Oj.load(File.read("test/fixtures/files/beanconqueror_real.json"))["brewFlow"]
    @new_timeframe = []
    relevant_keys = brew_flow.keys.select { |k| brew_flow[k].size > 1 }
    @new_data = DATA_LABELS_MAP.values_at(*relevant_keys).index_with { |label| [] }
    brew_flow.each do |label, data|
      data.each do |d|
        d["unix_timestamp"] = Time.strptime(d["timestamp"], "%H:%M:%S.%L").to_f
      end
    end
    longest = brew_flow.keys.max_by { |l| brew_flow[l].size }
    start = brew_flow[longest].first["unix_timestamp"].to_f
    brew_flow[longest].each do |d|
      @new_timeframe << (d["unix_timestamp"] - start).round(4).to_s
      relevant_keys.each do |key|
        closest = closest_bsearch(brew_flow[key], d["unix_timestamp"], key: "unix_timestamp")
        value = closest[DATA_VALUES_MAP[key]]
        @new_data[DATA_LABELS_MAP[key]] << (value&.positive? ? value : 0)
      end
    end
  end

  private

  def file_from_content(filename, content)
    file = Tempfile.new(filename)
    file.write(content)
    file.close
    file.path
  end
end

# == Schema Information
#
# Table name: shot_informations
#
#  id             :uuid             not null, primary key
#  brewdata       :jsonb
#  data           :jsonb
#  extra          :jsonb
#  profile_fields :jsonb
#  timeframe      :jsonb
#  shot_id        :uuid             not null
#
# Indexes
#
#  index_shot_informations_on_shot_id  (shot_id)
#
# Foreign Keys
#
#  fk_rails_...  (shot_id => shots.id)
#
