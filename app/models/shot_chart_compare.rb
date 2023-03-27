# frozen_string_literal: true

class ShotChartCompare < ShotChart
  extend Memoist

  attr_reader :comparison

  SUFFIX = "_comparison"

  def initialize(shot, comparison, user)
    @comparison = comparison
    super(shot, user)
  end

  def comparison_data
    (shot_chart + temperature_chart).filter_map do |s|
      next unless s[:name].ends_with?("Comparison")

      [s[:name], s[:data]]
    end.to_h
  end

  memoize def timestep
    longest_timeframe ||= processed_shot_data.max_by { |_k, v| v.size }.second.map(&:first)
    ((longest_timeframe.last - longest_timeframe.first) / longest_timeframe.size).round
  end

  memoize def duration
    processed_shot_data.map { |_, v| v.last.first }.max
  end

  private

  def prepare_chart_data
    super
    @processed_shot_data = @processed_shot_data.merge(process_data(comparison, label_suffix: SUFFIX))

    if @processed_shot_data["espresso_pressure_comparison"].present?
      @processed_shot_data["espresso_resistance_comparison"] = resistance_chart(@processed_shot_data["espresso_pressure_comparison"], @processed_shot_data["espresso_flow_comparison"]) if @processed_shot_data["espresso_pressure_comparison"].present? && @processed_shot_data["espresso_flow_comparison"].present?
      @processed_shot_data["espresso_conductance_comparison"] = conductance_chart(@processed_shot_data["espresso_pressure_comparison"], @processed_shot_data["espresso_flow_comparison"]) if @processed_shot_data["espresso_pressure_comparison"].present? && @processed_shot_data["espresso_flow_comparison"].present?
      @processed_shot_data["espresso_conductance_derivative_comparison"] = conductance_derivative_chart(@processed_shot_data["espresso_conductance_comparison"]) if @processed_shot_data["espresso_conductance_comparison"].present?
    end

    normalize_processed_shot_data
  end

  def normalize_processed_shot_data
    processed_shot_data.each do |k, v|
      comparison = k =~ /_comparison$/
      v.size.times do |i|
        v[i][0] = position_for(i, comparison).to_i * timestep
      end
    end
  end

  def position_for(original, comparison)
    if fidelity_ratio < 1 && comparison
      original / fidelity_ratio
    elsif fidelity_ratio > 1 && !comparison
      original * fidelity_ratio
    else
      original
    end
  end

  memoize def fidelity_ratio
    longest_original = processed_shot_data.max_by { |k, v| k.ends_with?("_comparison") ? 0 : v.size }.second.map(&:first)
    original_step = ((longest_original.last - longest_original.first) / longest_original.size)
    longest_comparison = processed_shot_data.max_by { |k, v| k.ends_with?("_comparison") ? v.size : 0 }.second.map(&:first)
    comparison_step = ((longest_comparison.last - longest_comparison.first) / longest_comparison.size)
    original_step / comparison_step
  end
end
