class AddCanonicalCoffeeBagToCoffeeBags < ActiveRecord::Migration[8.0]
  def change
    add_reference :coffee_bags, :canonical_coffee_bag, null: true, foreign_key: true, type: :uuid
  end
end
