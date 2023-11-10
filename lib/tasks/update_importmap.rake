# frozen_string_literal: true

require "concurrent"

class ImportMapUpdater
  attr_reader :file, :content, :mutex

  def initialize
    @file = Rails.root.join("config/importmap.rb")
    @content = File.read(file)
    @mutex = Mutex.new
  end

  def update
    futures.map do |future|
      result = future.value
      if result&.dig(:error)
        puts "Error: #{result[:error]}"
      elsif result
        mutex.synchronize do
          puts "Updating #{result[:current]} to #{result[:pinned_url]}"
          content.sub!("to: \"#{result[:current]}\"", "to: \"#{result[:pinned_url]}\"")
        end
      end
    end

    File.write(file, content)
  end

  private

  def futures
    @futures ||= content.split("\n").filter_map { |line| create_future(line) }
  end

  def create_future(line)
    return unless line.include?("# source:")

    Concurrent::Future.execute do
      uri = URI(line[/# source: (\S+)/, 1])
      res = Net::HTTP.get_response(uri)
      if res.is_a?(Net::HTTPSuccess)
        pinned_url = res.body[/Normal: (\S+)$/, 1]
        current = line[/to: "(\S+)"/, 1]
        {current:, pinned_url:, line:} unless pinned_url == current
      else
        {error: res.body}
      end
    end
  end
end

namespace :importmap do
  task update: :environment do
    ImportMapUpdater.new.update
  end
end
