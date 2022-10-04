# frozen_string_literal: true

task fill_duration: :environment do
  puts "Filling duration for #{Shot.where(duration: nil).count} shots"
  i = 0
  Shot.where(duration: nil).find_each do |shot|
    index = [shot.data["espresso_flow"].size, shot.timeframe.size].min
    shot.update_columns(duration: shot.timeframe[index - 1].to_f) # rubocop:disable Rails/SkipsModelValidations
    i += 1

    puts "#{i} done" if (i % 1000).zero?
  end
end
