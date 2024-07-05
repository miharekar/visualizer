class AddCoffeeManagementEnabledToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :coffee_management_enabled, :boolean
  end
end
