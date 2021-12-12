# frozen_string_literal: true

class ShotChartCompare < ShotChart
  attr_reader :comparison

  SUFFIX = "_comparison"

  def initialize(shot, comparison, chart_settings)
    @comparison = comparison
    super(shot, chart_settings)
  end

  def comparison_data
    (shot_chart + temperature_chart).filter_map do |s|
      next unless s[:name].ends_with?("Comparison")

      [s[:name], s[:data]]
    end.to_h
  end

  def multiplier
    shot_chart.max_by { |s| s[:data].last[0] }[:data].last[0] / 1000.0
  end

  private

  def prepare_chart_data
    super
    @processed_shot_data = @processed_shot_data.merge(process_data(comparison, label_suffix: SUFFIX))
    @processed_shot_data["espresso_resistance_comparison"] = resistance_chart(@processed_shot_data["espresso_pressure_comparison"], @processed_shot_data["espresso_flow_comparison"])
    normalize_processed_shot_data
  end

  def setting_for(label)
    return super unless label.end_with?(SUFFIX)

    og_label = label.sub(SUFFIX, "")
    setting = chart_settings[og_label].presence || CHART_SETTINGS[og_label]
    return unless setting

    setting = CHART_SETTINGS[og_label].merge(setting)
    setting.merge("opacity" => 0.6, "title" => "#{setting['title']} Comparison")
  end

  def normalize_processed_shot_data
    longest = processed_shot_data.max_by { |_k, v| v.size }
    timeframe = longest.second.map(&:first)
    processed_shot_data.each do |_k, v|
      v.size.times do |i|
        v[i][0] = timeframe[i]
      end
    end
  end
end
