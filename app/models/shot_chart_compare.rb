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

  def normalized_timeframe
    @normalized_timeframe ||= (0..longest_timeframe.size).map { |i| i * timestep }
  end

  def timestep
    @timestep ||= ((longest_timeframe.last - longest_timeframe.first) / longest_timeframe.size).round
  end

  def fidelity_ratio
    @fidelity_ratio ||= calculate_fidelity_ratio
  end

  private

  def longest_timeframe
    @longest_timeframe ||= processed_shot_data.max_by { |_k, v| v.size }.second.map(&:first)
  end

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

  def calculate_fidelity_ratio
    grouped = processed_shot_data.group_by { |k, _| k.ends_with?("_comparison") }
    longest_comparison = grouped[true].max_by { |_k, v| v.size }.second.map(&:first)
    comparison_step = ((longest_comparison.last - longest_comparison.first) / longest_comparison.size)
    longest_original = grouped[false].max_by { |_k, v| v.size }.second.map(&:first)
    original_step = ((longest_original.last - longest_original.first) / longest_original.size)
    original_step / comparison_step
  end

  def normalize_processed_shot_data
    processed_shot_data.each do |k, v|
      comparison = k =~ /_comparison$/
      v.size.times do |i|
        v[i][0] = normalized_timeframe[index_for(i, comparison)]
      end
    end
  end

  def index_for(original, comparison)
    if fidelity_ratio < 1 && comparison
      original / fidelity_ratio
    elsif fidelity_ratio > 1 && !comparison
      original * fidelity_ratio
    else
      original
    end
  end
end
