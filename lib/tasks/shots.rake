# frozen_string_literal: true

namespace :shots do
  task copy_data: :environment do
    missing = Shot.pluck(:id) - ShotInformation.pluck(:shot_id)
    puts "Filling data for #{missing.count} shots"
    i = 0
    attrs = ["id"] + Shot::INFORMATION_KEYS
    info_attrs = ["shot_id"] + Shot::INFORMATION_KEYS
    missing.in_groups_of(100, false) do |group|
      ActiveRecord::Base.transaction do
        informations = Shot.where(id: group).pluck(*attrs).map { |s| info_attrs.zip(s).to_h }
        ShotInformation.insert_all!(informations) # rubocop:disable Rails/SkipsModelValidations
      end

      i += group.size
      puts "#{i} done" if (i % 1000).zero?
    end
  end
end
