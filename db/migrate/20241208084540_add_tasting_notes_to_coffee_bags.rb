class AddTastingNotesToCoffeeBags < ActiveRecord::Migration[8.0]
  def change
    add_column :coffee_bags, :tasting_notes, :string
  end
end
