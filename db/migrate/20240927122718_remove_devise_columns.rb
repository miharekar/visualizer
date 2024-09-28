class RemoveDeviseColumns < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :encrypted_password, :password_digest

    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
  end
end
