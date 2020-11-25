# frozen_string_literal: true

class Shot < ApplicationRecord
  RELEVANT_LABELS = %w[espresso_pressure espresso_weight espresso_flow espresso_flow_weight espresso_temperature_basket espresso_temperature_mix espresso_water_dispensed espresso_temperature_goal espresso_flow_weight_raw espresso_pressure_goal espresso_flow_goal espresso_resistance].freeze

  def chart_data
    chart_from_data + calculated_chart_data
  end

  def stages
    indices = []
    data.select { |d| d["label"].end_with?("_goal") }.each do |goal|
      goal["data"].each_with_index do |a, i|
        next if i < 4

        b = goal["data"][i - 1]
        c = goal["data"][i - 2]
        d = goal["data"][i - 3]
        e = goal["data"][i - 4]
        indices << i if e == d && d == c && c == b && b != a
      end
    end
    chart_from_data.first[:data].values_at(*indices.uniq).pluck(:t)
  end

  private

  def chart_from_data
    @chart_from_data ||= data.map do |d|
      next if RELEVANT_LABELS.exclude?(d["label"]) || d["label"] == "espresso_elapsed"

      {label: d["label"], data: d["data"].map.with_index { |v, i| {t: timeframe[i].to_f * 1000, y: (v.to_f.negative? ? nil : v)} }}
    end.compact
  end

  def calculated_chart_data
    @calculated_chart_data ||= [resistance_chart]
  end

  def resistance_chart
    data = pressure_data.map.with_index do |v, i|
      f = flow_data[i][:y].to_f
      if f.zero?
        {t: v[:t], y: nil}
      else
        r = v[:y].to_f / f
        {t: v[:t], y: (r > 15 ? nil : r)}
      end
    end

    {label: "espresso_resistance", data: data}
  end

  def pressure_data
    @pressure_data ||= chart_from_data.find { |d| d[:label] == "espresso_pressure" }[:data]
  end

  def flow_data
    @flow_data ||= chart_from_data.find { |d| d[:label] == "espresso_flow" }[:data]
  end

  def timeframe
    @timeframe ||= data.find { |d| d["label"] == "espresso_elapsed" }["data"]
  end
end

# == Schema Information
#
# Table name: shots
#
#  id            :uuid             not null, primary key
#  data          :jsonb
#  profile_title :string
#  start_time    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
