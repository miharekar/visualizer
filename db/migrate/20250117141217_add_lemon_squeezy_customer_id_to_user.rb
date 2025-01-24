class AddLemonSqueezyCustomerIdToUser < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :lemon_squeezy_customer_id, :string
    add_index :users, :lemon_squeezy_customer_id, unique: true
  end
end
