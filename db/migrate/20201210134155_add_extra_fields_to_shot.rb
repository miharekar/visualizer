# frozen_string_literal: true

class AddExtraFieldsToShot < ActiveRecord::Migration[6.0]
  def change
    add_column :shots, :extra, :jsonb
  end
end
