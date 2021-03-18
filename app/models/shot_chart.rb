# frozen_string_literal: true

class ShotChart
  extend Memoist

  SKINS = ["Classic", "DSx", "White DSx"].freeze
  DATA_LABELS_TO_IGNORE = %w[espresso_resistance espresso_resistance_weight espresso_state_change].freeze
  MAX_RESISTANCE_VALUE = 16

  attr_reader :shot

  def initialize(shot)
    @shot = shot
    @temperature_data, @main_data = chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label].include?("temperature") }
  end

  def shot_data
    @main_data.map do |line|
      {
        name: line[:label],
        data: line[:data].map { |d| [d[:t], d[:y]] },
        visible: %w[espresso_water_dispensed espresso_weight].exclude?(line[:label])
      }
    end
  end

  def temperature_data
    @temperature_data.map do |line|
      {
        name: line[:label],
        data: line[:data].map { |d| [d[:t], d[:y]] }
      }
    end
  end

  def stages
    chart_data.first[:data].values_at(*stage_indices).pluck(:t).map { |s| {value: s} }
  end

  private

  def chart_data
    chart_from_data + [resistance_chart]
  end

  memoize def chart_from_data
    timeframe = shot.timeframe
    timeframe_count = timeframe.count
    timeframe_last = timeframe.last.to_f
    timeframe_diff = (timeframe_last + timeframe.first.to_f) / timeframe.count.to_f
    shot.data.map do |label, data|
      next if DATA_LABELS_TO_IGNORE.include?(label)

      times10 = label == "espresso_water_dispensed"
      data = data.map.with_index do |v, i|
        t = i < timeframe_count ? timeframe[i] : timeframe_last + ((i - timeframe_count + 1) * timeframe_diff)
        v = v.to_f
        v *= 10 if times10
        v = nil if v.negative?
        {t: t.to_f * 1000, y: v}
      end
      {label: label, data: data}
    end.compact
  end

  def resistance_chart
    pressure_data = chart_from_data.find { |d| d[:label] == "espresso_pressure" }[:data]
    flow_data = chart_from_data.find { |d| d[:label] == "espresso_flow" }[:data]
    data = pressure_data.map.with_index do |v, i|
      f = flow_data[i][:y].to_f
      if f.zero?
        {t: v[:t], y: nil}
      else
        r = v[:y].to_f / f
        {t: v[:t], y: (r > MAX_RESISTANCE_VALUE ? nil : r)}
      end
    end

    {label: "espresso_resistance", data: data}
  end

  def stage_indices
    shot.data.key?("espresso_state_change") ? stages_from_state_change(shot.data) : detect_stages_from_data(shot.data)
  end

  def stages_from_state_change(data)
    indices = []

    current = data["espresso_state_change"].find { |s| !s.to_i.zero? }
    data["espresso_state_change"].each.with_index do |s, i|
      next if s.to_i.zero? || s == current

      indices << i
      current = s
    end
    indices
  end

  def detect_stages_from_data(data)
    indices = []
    data.select { |label, _| label.end_with?("_goal") }.each do |_label, data|
      data = data.map(&:to_f)
      data.each.with_index do |a, i|
        next if i < 5

        b = data[i - 1]
        c = data[i - 2]
        diff2 = ((a - b) - (b - c))
        indices << i if diff2.abs > 0.1
      end
    end

    if indices.any?
      indices = indices.sort.uniq
      selected = [indices.first]
      indices.each do |index|
        selected << index if (index - selected.last) > 5
      end
    end
    selected
  end
end
