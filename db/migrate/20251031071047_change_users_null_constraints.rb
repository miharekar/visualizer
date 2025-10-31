class ChangeUsersNullConstraints < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = :users
  end

  def change
    reversible do |dir|
      dir.up do
        MigrationUser.where(public: nil).update_all(public: false)
        MigrationUser.where(supporter: nil).update_all(supporter: false)
        MigrationUser.where(admin: nil).update_all(admin: false)
        MigrationUser.where(hide_shot_times: nil).update_all(hide_shot_times: false)
        MigrationUser.where(beta: nil).update_all(beta: false)
        MigrationUser.where(developer: nil).update_all(developer: false)
        MigrationUser.where(coffee_management_enabled: nil).update_all(coffee_management_enabled: false)
      end
    end

    change_column_null :users, :public, false
    change_column_null :users, :supporter, false
    change_column_null :users, :admin, false
    change_column_null :users, :hide_shot_times, false
    change_column_null :users, :beta, false
    change_column_null :users, :developer, false
    change_column_null :users, :coffee_management_enabled, false
  end
end
