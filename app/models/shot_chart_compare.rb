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
    @processed_shot_data = process_data(shot) + process_data(comparison, label_suffix: SUFFIX)
    normalize_processed_shot_data
  end

  def setting_for(label)
    return super unless label.end_with?(SUFFIX)

    setting = skin[label.sub(SUFFIX, "")]
    setting.merge(title: [setting[:title], " Comparison"].join)
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
