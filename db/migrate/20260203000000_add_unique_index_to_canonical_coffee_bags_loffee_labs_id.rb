class AddUniqueIndexToCanonicalCoffeeBagsLoffeeLabsId < ActiveRecord::Migration[8.0]
  def change
    add_index :canonical_coffee_bags, :loffee_labs_id, unique: true
  end
end
