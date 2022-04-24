# frozen_string_literal: true

class AddRoastLevelToShots < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :roast_level, :string
  end
end
