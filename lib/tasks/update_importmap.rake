# frozen_string_literal: true

namespace :importmap do
  task update: :environment do
    file = Rails.root.join("config/importmap.rb")
    content = File.read(file)
    content.split("\n").each do |line|
      next unless line.include?("# source:")

      uri = URI(line[/# source: (\S+)/, 1])
      res = Net::HTTP.get_response(uri)
      if res.is_a?(Net::HTTPSuccess)
        pinned_url = res.body[/Normal: (\S+)$/, 1]
        current = line[/to: "(\S+)"/, 1]
        next if pinned_url == current

        puts "Updating #{current} to #{pinned_url}"
        content.sub!("to: \"#{current}\"", "to: \"#{pinned_url}\"")
      else
        puts "Error: #{res.body}"
      end
    end

    file.write(content)
  end
end
