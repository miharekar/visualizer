class AddAdminToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :admin, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
