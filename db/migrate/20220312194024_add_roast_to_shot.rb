# frozen_string_literal: true

class AddRoastToShot < ActiveRecord::Migration[7.0]
  def change
    add_reference :shots, :coffee_roast, foreign_key: true, type: :uuid
  end
end
