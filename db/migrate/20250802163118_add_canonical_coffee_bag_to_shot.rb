class AddCanonicalCoffeeBagToShot < ActiveRecord::Migration[8.0]
  def change
    add_reference :shots, :canonical_coffee_bag, foreign_key: true, type: :uuid
  end
end
