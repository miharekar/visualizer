# frozen_string_literal: true

class AddTemperatureUnitToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :temperature_unit, :string
  end
end
