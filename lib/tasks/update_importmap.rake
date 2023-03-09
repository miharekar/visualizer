# frozen_string_literal: true

namespace :importmap do
  task update: :environment do
    file = Rails.root.join("config/importmap.rb")
    content = File.read(file)
    content.split("\n").each do |line|
      next unless line.include?("jspm")

      matches = line.match(/npm:(?<package>[^@]+)@(?<version>[^\/]+)\//)
      uri = URI("https://registry.npmjs.org/#{matches[:package]}/latest")
      res = Net::HTTP.get_response(uri)
      if res.is_a?(Net::HTTPSuccess)
        data = JSON.parse(res.body)
        version = data["version"]
        next if version == matches[:version]

        puts "Updating #{matches[:package]} from #{matches[:version]} to #{version}"
        content.sub!(/npm:#{matches[:package]}@#{matches[:version]}\//, "npm:#{matches[:package]}@#{version}/")
      else
        puts "Error: #{res.body}"
      end
    end

    file.write(content)
  end
end
