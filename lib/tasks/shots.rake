# frozen_string_literal: true

namespace :shots do
  task copy_data: :environment do
    missing = Shot.pluck(:id) - ShotInformation.pluck(:shot_id)
    puts "Filling data for #{missing.count} shots"
    i = 0
    Shot.where(id: missing).find_each do |shot|
      next unless missing.include?(shot.id)

      ShotInformation.from_shot(shot)
      i += 1
      puts "#{i} done" if (i % 1000).zero?
    end
  end
end
