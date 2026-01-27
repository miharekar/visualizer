require_relative "../../app/models/application_record.rb"

class ProdBase < ApplicationRecord
  self.abstract_class = true
end

class ProdShot < ProdBase
  self.table_name = "shots"
end

class ProdShotInformation < ProdBase
  self.table_name = "shot_informations"
end

class LocalBase < ApplicationRecord
  self.abstract_class = true
end

class LocalUser < LocalBase
  self.table_name = "users"
end

class LocalShot < LocalBase
  self.table_name = "shots"
end

class LocalShotInformation < LocalBase
  self.table_name = "shot_informations"
end

class LocalCoffeeBag < LocalBase
  self.table_name = "coffee_bags"
end

class LocalCanonicalCoffeeBag < LocalBase
  self.table_name = "canonical_coffee_bags"
end

namespace :data do
  desc "Copy a shot and shot information from production to local"
  task :copy_shot_from_prod, [:shot_id] => :environment do |_, args|
    shot_id = args[:shot_id]

    if shot_id.blank?
      puts "Usage: bin/rails data:copy_shot_from_prod[SHOT_ID]"
      exit 1
    end

    prod_config = {
      adapter: "postgresql",
      encoding: "unicode",
      host: "localhost",
      port: 15432,
      database: "visualizer_production",
      username: "visualizer",
      password: ENV["POSTGRES_PASSWORD"],
      variables: {statement_timeout: "10s"}
    }

    if prod_config[:password].blank?
      puts "POSTGRES_PASSWORD is required to connect to production."
      exit 1
    end

    local_config = {
      adapter: "postgresql",
      encoding: "unicode",
      host: "localhost",
      port: 5432,
      database: "visualizer_development",
      variables: {statement_timeout: "10s"}
    }

    ProdBase.establish_connection(prod_config)
    LocalBase.establish_connection(local_config)

    source_shot = ProdShot.find_by(id: shot_id)

    if source_shot.blank?
      puts "Shot #{shot_id} not found in production."
      exit 1
    end

    target_user_id = source_shot.user_id

    if target_user_id.present? && !LocalUser.exists?(id: target_user_id)
      puts "Local user #{target_user_id} not found. Create the user in local before copying the shot."
      exit 1
    end

    shot_attrs = source_shot.attributes
    shot_attrs["user_id"] = target_user_id
    shot_attrs["coffee_bag_id"] = nil if shot_attrs["coffee_bag_id"].present? && !LocalCoffeeBag.exists?(id: shot_attrs["coffee_bag_id"])

    shot_attrs["canonical_coffee_bag_id"] = nil if shot_attrs["canonical_coffee_bag_id"].present? && !LocalCanonicalCoffeeBag.exists?(id: shot_attrs["canonical_coffee_bag_id"])

    # rubocop:disable Rails/SkipsModelValidations
    LocalShot.upsert(shot_attrs, unique_by: :id)

    source_info = ProdShotInformation.find_by(shot_id:)

    if source_info.present?
      info_attrs = source_info.attributes
      info_attrs["shot_id"] = shot_id
      LocalShotInformation.upsert(info_attrs, unique_by: :id)
      puts "Copied shot and shot information."
    else
      puts "Copied shot only (no shot information in production)."
    end
    # rubocop:enable Rails/SkipsModelValidations
  end
end
