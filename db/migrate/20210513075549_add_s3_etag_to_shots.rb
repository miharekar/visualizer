# frozen_string_literal: true

class AddS3EtagToShots < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :s3_etag, :string
  end
end
