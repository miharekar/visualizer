class ChangeShotsNullConstraints < ActiveRecord::Migration[8.1]
  class MigrationShot < ApplicationRecord
    self.table_name = :shots
  end

  def change
    reversible do |dir|
      dir.up do
        MigrationShot.where(public: nil).update_all(public: false)
      end
    end

    change_column_null :shots, :start_time, false
    change_column_null :shots, :sha, false
    change_column_null :shots, :public, false
  end
end
