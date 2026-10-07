class AddConfirmedAtToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :confirmed_at, :datetime
    up_only { execute "UPDATE users SET confirmed_at = created_at" }
  end
end
