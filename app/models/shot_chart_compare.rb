# frozen_string_literal: true

class ShotChartCompare < ShotChart
  attr_reader :comparison

  SUFFIX = "_comparison"

  def initialize(shot, comparison, skin: nil)
    @comparison = comparison
    super(shot, skin: skin)
  end

  private

  def prepare_chart_data
    comparison_data = process_data(comparison, label_suffix: SUFFIX)
    pp comparison_data.map{|d| d[:label]}
    pressure_data = comparison_data.find { |d| d[:label] == "espresso_pressure_comparison" }[:data]
    flow_data = comparison_data.find { |d| d[:label] == "espresso_flow_comparison" }[:data]
    @processed_shot_data = super + comparison_data + [resistance_chart(pressure_data, flow_data, label_suffix: SUFFIX)]
    normalize_processed_shot_data
  end

  def setting_for(label)
    return super unless label.end_with?(SUFFIX)

    og_label = label.sub(SUFFIX, "")
    return unless skin.key?(og_label)

    setting = skin[og_label]
    setting.merge(
      title: [setting[:title], " Comparison"].join,
      color: setting[:color].sub(/^rgb\((.*)\)$/, "rgba(\\1, 0.6)")
    )
  end

  def normalize_processed_shot_data
    longest = processed_shot_data.max_by { |line| line[:data].size }
    timeframe = longest[:data].map(&:first)
    processed_shot_data.each do |line|
      line[:data].size.times do |i|
        line[:data][i][0] = timeframe[i]
      end
    end
  end
end
