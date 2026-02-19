class RenameUserMetadataFieldsToShotMetadataFields < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :metadata_fields, :shot_metadata_fields
  end
end
