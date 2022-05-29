# frozen_string_literal: true

class AddBagToShot < ActiveRecord::Migration[7.0]
  def change
    add_reference :shots, :coffee_bags, foreign_key: true, type: :uuid
  end
end
