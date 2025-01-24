class DropCustomerAndSubscriptionsTable < ActiveRecord::Migration[8.0]
  def up
    drop_table :subscriptions
    drop_table :customers
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
