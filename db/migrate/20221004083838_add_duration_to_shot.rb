# frozen_string_literal: true

class AddDurationToShot < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :duration, :float
  end
end
