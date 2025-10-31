class ChangeDropdownValuesKindNullConstraint < ActiveRecord::Migration[8.1]
  def change
    change_column_null :dropdown_values, :kind, false
  end
end
