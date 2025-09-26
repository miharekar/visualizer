class AddPlaceOfPurchaseToCoffeeBean < ActiveRecord::Migration[8.1]
  def change
    add_column :coffee_bags, :place_of_purchase, :string
  end
end
