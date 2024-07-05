class AddCoffeeBagToShot < ActiveRecord::Migration[7.1]
  def change
    add_reference :shots, :coffee_bag, foreign_key: true, type: :uuid
  end
end
