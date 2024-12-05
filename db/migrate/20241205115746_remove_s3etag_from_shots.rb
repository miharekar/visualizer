class RemoveS3etagFromShots < ActiveRecord::Migration[8.0]
  def change
    remove_column :shots, :s3_etag, :string
  end
end
