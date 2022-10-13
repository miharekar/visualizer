# frozen_string_literal: true

class RemoveColumnsFromShot < ActiveRecord::Migration[7.0]
  def change
    remove_column :shots, :data, :jsonb
    remove_column :shots, :extra, :jsonb
    remove_column :shots, :profile_fields, :jsonb
    remove_column :shots, :timeframe, :jsonb
  end
end
