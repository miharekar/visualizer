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
  @labels = elapsed[:data].map { |i| (@start_time + i.to_f) }
  @data = @data.map do |d|
    next if d[:label] == "espresso_elapsed"
    {
      label: d[:label],
      data: d[:data].map.with_index { |v, i| {t: @labels[i].to_i * 1000, y: v} }
    }
  end.compact
  @labels = @labels.map { |t| t.strftime("%T")}

  slim :index
end
