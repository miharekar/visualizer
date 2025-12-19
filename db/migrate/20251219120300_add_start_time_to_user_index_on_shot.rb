class AddStartTimeToUserIndexOnShot < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    add_index :shots, [:user_id, :start_time], algorithm: :concurrently
    remove_index :shots, :user_id
  end
end
