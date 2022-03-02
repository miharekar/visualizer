# frozen_string_literal: true

class RemoveCloudinaryIdFromShots < ActiveRecord::Migration[7.0]
  def change
    remove_column :shots, :cloudinary_id, :string
  end
end
