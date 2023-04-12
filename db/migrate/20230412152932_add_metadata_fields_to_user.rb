# frozen_string_literal: true

class AddMetadataFieldsToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :metadata_fields, :jsonb
  end
end
