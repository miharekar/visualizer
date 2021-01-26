# frozen_string_literal: true

require "slim/erb_converter"

namespace :slim_to_erb do
  task :convert do
    FileUtils.rm_f("tmp/compiled.html.erb")
    File.open(Rails.root.join("tmp/compiled.html.erb"), "w+") do |compiled|
      Dir.glob(Rails.root.join("app/views/**/*.html.slim")).each do |slim_template|
        File.open(slim_template) do |f|
          slim_code = f.read
          erb_code = Slim::ERBConverter.new.call(slim_code)
          compiled.puts(erb_code)
        end
      end
    end
  end
end

Rake::Task["webpacker:compile"].enhance(["slim_to_erb:convert"])
