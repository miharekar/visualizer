# frozen_string_literal: true

class AddMoreFieldsToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :drink_tds, :string
    add_column :shots, :drink_ey, :string
    add_column :shots, :espresso_enjoyment, :string
    add_column :shots, :bean_weight, :string
    add_column :shots, :drink_weight, :string
    add_column :shots, :grinder_model, :string
    add_column :shots, :grinder_setting, :string
    add_column :shots, :bean_brand, :string
    add_column :shots, :bean_type, :string
    add_column :shots, :roast_date, :string
  end
end
