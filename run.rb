# frozen_string_literal: true

require "sinatra"
require "sinatra/json"

if development?
  require "sinatra/reloader"
  require "pry"
end

set :public_folder, "public"

def parse_shot_file(file)
  file.lines.map do |line|
    next unless line =~ /\{[\-\d. ]{10,}\}/

    key, values = line.split(" {")
    {label: key, data: values.split(" ")}
  end.compact
end

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

get "/" do
  slim :index
end

post "/" do
  file = File.read(params["file"]["tempfile"])
  @start_time = Time.at(file[/clock (\d+)/, 1].to_i)
  parsed_file = parse_shot_file(file)
  elapsed = parsed_file.find { |d| d[:label] == "espresso_elapsed" }
  @time = elapsed[:data].map { |i| (@start_time + i.to_f) }
  @data = parsed_file.map do |d|
    next if d[:label] == "espresso_elapsed"

    unless CHART_CONFIG.key?(d[:label])
      p "Missing #{d[:label]}"
      next
    end

    {
      label: CHART_CONFIG[d[:label]][:title],
      data: d[:data].map.with_index { |v, i| {t: @time[i].to_f * 1000, y: v} },
      borderColor: CHART_CONFIG[d[:label]][:border_color],
      backgroundColor: CHART_CONFIG[d[:label]][:background_color],
      borderDash: CHART_CONFIG[d[:label]][:border_dash],
      fill: CHART_CONFIG[d[:label]][:fill],
      pointRadius: 0
    }
  end.compact
  @temperature_data, @data = @data.sort_by { |d| d[:label] }.partition { |d| d[:label] =~ /Temperature/ }
  slim :chart
end
