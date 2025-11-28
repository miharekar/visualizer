class AddNotesToCoffeeBag < ActiveRecord::Migration[8.1]
  def change
    add_column :coffee_bags, :notes, :text
  end
end
