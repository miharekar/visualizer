# frozen_string_literal: true

class ShotParser
  CHART_CONFIG = {
    "espresso_pressure" => {title: "Pressure", border_color: "rgba(5, 199, 147, 1)", background_color: "rgba(5, 199, 147, 0.7)", border_dash: [], fill: true},
    "espresso_weight" => {title: "Weight", border_color: "rgba(143, 100, 0, 1)", background_color: "rgba(143, 100, 0, 0.7)", border_dash: [], fill: true},
    "espresso_flow" => {title: "Flow", border_color: "rgba(31, 183, 234, 1)", background_color: "rgba(31, 183, 234, 0.7)", border_dash: [], fill: true},
    "espresso_flow_weight" => {title: "Flow Weight", border_color: "rgba(17, 138, 178, 1)", background_color: "rgba(17, 138, 178, 0.7)", border_dash: [], fill: true},
    "espresso_temperature_basket" => {title: "Temperature Basket", border_color: "rgba(240, 86, 122, 1)", background_color: "rgba(240, 86, 122, 0.7)", border_dash: [], fill: false},
    "espresso_temperature_mix" => {title: "Temperature Mix", border_color: "rgba(206, 18, 62, 1)", background_color: "rgba(206, 18, 62, 0.7)", border_dash: [], fill: false},
    "espresso_water_dispensed" => {title: "Water Dispensed", border_color: "rgba(31, 183, 234, 1)", background_color: "rgba(31, 183, 234, 0.7)", border_dash: [], fill: true},
    "espresso_temperature_goal" => {title: "Temperature Goal", border_color: "rgba(150, 13, 45, 1)", background_color: "rgba(150, 13, 45, 0.7)", border_dash: [5, 5], fill: false},
    "espresso_flow_weight_raw" => {title: "Flow Weight Raw", border_color: "rgba(17, 138, 178, 1)", background_color: "rgba(17, 138, 178, 1)", border_dash: [], fill: false},
    "espresso_pressure_goal" => {title: "Pressure Goal", border_color: "rgba(3, 99, 74, 1)", background_color: "rgba(3, 99, 74, 1)", border_dash: [5, 5], fill: false},
    "espresso_flow_goal" => {title: "Flow Goal", border_color: "rgba(9, 72, 93, 1)", background_color: "rgba(9, 72, 93, 1)", border_dash: [5, 5], fill: false}
  }.freeze

  attr_reader :start_time, :temperature_data, :data_without_temperature

  def initialize(file)
    @file = file
    @parsed = parsed_file
    @start_time = Time.at(@file[/clock (\d+)/, 1].to_i)
    @temperature_data, @data_without_temperature = chart_data.sort_by { |d| d[:label] }.partition { |d| d[:label] =~ /Temperature/ }
  end

  def chart_data
    timeframe = @parsed.find { |d| d[:label] == "espresso_elapsed" }[:data]
    @parsed.map do |d|
      next if !CHART_CONFIG.key?(d[:label]) || d[:label] == "espresso_elapsed"

      {
        label: CHART_CONFIG[d[:label]][:title],
        data: d[:data].map.with_index { |v, i| {t: timeframe[i].to_f * 1000, y: v} },
        borderColor: CHART_CONFIG[d[:label]][:border_color],
        backgroundColor: CHART_CONFIG[d[:label]][:background_color],
        borderDash: CHART_CONFIG[d[:label]][:border_dash],
        fill: CHART_CONFIG[d[:label]][:fill],
        pointRadius: 0
      }
    end.compact
  end

  private

  def parsed_file
    @file.lines.map do |line|
      match = line.match(/(?<label>\w+) \{(?<data>[\-\d. ]+)\}/)
      next unless match

      {label: match[:label], data: match[:data].split(" ").map { |v| v == "-1.0" ? nil : v }}
    end.compact
  end
end
