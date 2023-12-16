class AddMetadataToShotInformation < ActiveRecord::Migration[7.1]
  def change
    add_column :shot_informations, :metadata, :jsonb
  end
end
