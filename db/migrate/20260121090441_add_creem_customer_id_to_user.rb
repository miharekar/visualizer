class AddCreemCustomerIdToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :creem_customer_id, :string
    add_index :users, :creem_customer_id, unique: true
  end
end
