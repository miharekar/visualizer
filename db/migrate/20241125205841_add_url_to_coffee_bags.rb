class AddUrlToCoffeeBags < ActiveRecord::Migration[8.0]
  def change
    add_column :coffee_bags, :url, :string
  end
end
