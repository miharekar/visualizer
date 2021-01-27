class AddSupporterToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :supporter, :boolean
  end
end
