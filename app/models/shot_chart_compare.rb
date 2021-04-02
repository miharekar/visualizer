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
    super
    @processed_shot_data = @processed_shot_data.merge(process_data(comparison, label_suffix: SUFFIX))
    @processed_shot_data["espresso_resistance_comparison"] = resistance_chart(@processed_shot_data["espresso_pressure_comparison"], @processed_shot_data["espresso_flow_comparison"])
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
    longest = processed_shot_data.max_by { |_k, v| v.size }
    timeframe = longest.second.map(&:first)
    processed_shot_data.each do |_k, v|
      v.size.times do |i|
        v[i][0] = timeframe[i]
      end
    end
  end
end
