class RemoveIndexDropdownValuesOnUserIdIndex < ActiveRecord::Migration[8.1]
  def change
    remove_index 'dropdown_values', name: 'index_dropdown_values_on_user_id'
  end
end
