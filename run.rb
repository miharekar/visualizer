require "sinatra"
require "sinatra/json"

if development?
  require "sinatra/reloader"
  require "pry"
end

def parse_shot_file(file)
  file.lines.map do |line|
    next unless line =~ /\{[\d\. ]{10,}\}/
    key, values = line.split(" {")
    [key, values.split(" ")]
  end.compact.to_h
end

CHART_CONFIG = {
  "espresso_pressure" => {title: "Pressure", color: "#222222"},
  "espresso_weight" => {title: "Weight", color: "#000000"},
  "espresso_flow" => {title: "Flow", color: "#444444"},
  "espresso_flow_weight" => {title: "Flow Weight", color: "#00FF00"},
  "espresso_temperature_basket" => {title: "Temperature Basket", color: "#FFEE00"},
  "espresso_temperature_mix" => {title: "Temperature Mix", color: "#FFFF00"},
  "espresso_water_dispensed" => {title: "Water Dispensed", color: "#0000FF"},
  "espresso_temperature_goal" => {title: "Temperature Goal", color: "#FF0000"},
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

    options = {
      label: CHART_CONFIG[d[:label]][:title],
      data: d[:data].map.with_index { |v, i| {t: @time[i].to_f * 1000, y: v} },
      borderColor: CHART_CONFIG[d[:label]][:color]
    }

    options = options.merge(fill: false) if d[:label] =~ /temperature/

    options
  end.compact

  slim :index
end
