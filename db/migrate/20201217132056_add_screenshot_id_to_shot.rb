# frozen_string_literal: true

class AddScreenshotIdToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :cloudinary_id, :string
  end
end
