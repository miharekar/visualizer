class RemoveDecentTokenFromUser < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :decent_email, :string
    remove_column :users, :decent_token, :string
  end
end
