# frozen_string_literal: true

require "sinatra"
require_relative "app/shot_parser"

set :public_folder, "public"

get "/" do
  slim :index
end

post "/" do
  file = File.read(params["file"]["tempfile"])
  shot = ShotParser.new(file)

  @time = shot.timeframe
  @temperature_data = shot.temperature_data
  @data = shot.data_without_temperature

  slim :chart
end
