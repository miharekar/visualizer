class AddTimezoneToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :timezone, :string
  end
end
