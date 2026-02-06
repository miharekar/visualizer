class AddFreezerDatesToCoffeeBags < ActiveRecord::Migration[8.0]
  def change
    add_column :coffee_bags, :frozen_date, :date
    add_column :coffee_bags, :defrosted_date, :date
  end
end
