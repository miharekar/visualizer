class ChangeRoastersNameNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :roasters, :name, false
  end
end
