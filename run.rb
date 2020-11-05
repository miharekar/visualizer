require "sinatra"
require "sinatra/json"

if development?
  require "sinatra/reloader"
  require "pry"
end

def parse_shot_file(file)
  file.lines.map do |line|
    next unless line =~ /\{[\-\d\. ]{10,}\}/
    key, values = line.split(" {")
    [key, values.split(" ")]
  end.compact.to_h
end

CHART_CONFIG = {
  "espresso_pressure" => {title: "Pressure", border_color: "#222222", background_color: "#222222", border_dash: [], fill: true},
  "espresso_weight" => {title: "Weight", border_color: "#000000", background_color: "#000000", border_dash: [], fill: true},
  "espresso_flow" => {title: "Flow", border_color: "#444444", background_color: "#444444", border_dash: [], fill: true},
  "espresso_flow_weight" => {title: "Flow Weight", border_color: "#00FF00", background_color: "#00FF00", border_dash: [], fill: true},
  "espresso_temperature_basket" => {title: "Temperature Basket", border_color: "#FFEE00", background_color: "#FFEE00", border_dash: [], fill: false},
  "espresso_temperature_mix" => {title: "Temperature Mix", border_color: "#FFFF00", background_color: "#FFFF00", border_dash: [], fill: false},
  "espresso_water_dispensed" => {title: "Water Dispensed", border_color: "#0000FF", background_color: "#0000FF", border_dash: [], fill: true},
  "espresso_temperature_goal" => {title: "Temperature Goal", border_color: "#FF0000", background_color: "#FF0000", border_dash: [5, 5], fill: false},
  "espresso_flow_weight_raw"  => {title: "Flow Weight Raw", border_color: "#00FF00", background_color: "#00FF00", border_dash: [], fill: false},
  "espresso_pressure_goal" => {title: "Pressure Goal", border_color: "#FF0000", background_color: "#FF0000", border_dash: [5, 5], fill: false},
  "espresso_flow_goal" => {title: "Flow Goal", border_color: "#FF0000", background_color: "#FF0000", border_dash: [5, 5], fill: false},
}

get "/" do
  file = File.read("test.shot")
  @start_time = Time.at(file[/clock ([\d]+)/, 1].to_i)
  @data = parse_shot_file(file).map do |key, values|
    {
      label: key,
      data: values
    }
  end
  elapsed = @data.find { |d| d[:label] == "espresso_elapsed" }
  @time = elapsed[:data].map { |i| (@start_time + i.to_f) }
  @data = @data.map do |d|
    next if d[:label] == "espresso_elapsed"

    {
      label: CHART_CONFIG[d[:label]][:title],
      data: d[:data].map.with_index { |v, i| {t: @time[i].to_f * 1000, y: v} },
      borderColor: CHART_CONFIG[d[:label]][:border_color],
      backgroundColor: CHART_CONFIG[d[:label]][:background_color],
      borderDash: CHART_CONFIG[d[:label]][:border_dash],
      fill: CHART_CONFIG[d[:label]][:fill],
      pointRadius: 0,
    }
  end.compact

  slim :index
end
