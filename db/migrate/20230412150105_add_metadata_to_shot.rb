# frozen_string_literal: true

class AddMetadataToShot < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :metadata, :jsonb
  end
end
