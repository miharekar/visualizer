# frozen_string_literal: true

class AddProfileFieldsToShot < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :profile_fields, :jsonb
  end
end
