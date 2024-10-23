require "concurrent"

class ImportMapChecker
  attr_reader :file, :content

  def initialize
    @file = Rails.root.join("config/importmap.rb")
    @content = File.read(file)
  end

  def check
    futures.each(&:value)
  end

  private

  def futures
    @futures ||= content.split("\n").filter_map { |line| create_future(line) }
  end

  def create_future(line)
    return unless line.include?("jsdelivr")

    Concurrent::Future.execute do
      current_url = line[/to: "(.*)"/, 1]
      non_versioned_url = current_url.sub(%r{@[\d]+/}, "/")
      current_version = URI(current_url)
      latest_version = URI(non_versioned_url)

      current = Net::HTTP.get_response(URI(current_version))
      if current.is_a?(Net::HTTPSuccess)
        latest = Net::HTTP.get_response(URI(latest_version))
        if latest.is_a?(Net::HTTPSuccess)
          puts "There is a new major version of #{current_url} available" if current.body != latest.body
        else
          puts "Could not fetch #{latest_version}"
        end
      else
        puts "Could not fetch #{current_version}"
      end
    end
  end
end

namespace :importmap do
  task check: :environment do
    ImportMapChecker.new.check
  end
end
