class ChangeDropdownValuesValueNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :dropdown_values, :value, false
  end
end
