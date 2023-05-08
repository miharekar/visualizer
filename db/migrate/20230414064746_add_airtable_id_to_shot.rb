# frozen_string_literal: true

class AddAirtableIdToShot < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :airtable_id, :string
    add_index :shots, :airtable_id
  end
end
