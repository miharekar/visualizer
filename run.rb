# frozen_string_literal: true

require "sinatra"
require_relative "app/shot_parser"

set :public_folder, "public"

get "/" do
  slim :index
end

post "/" do
  @shot = ShotParser.new(File.read(params["file"]["tempfile"]))
  slim :chart
end
