class ChangeShotIndexes < ActiveRecord::Migration[7.1]
  def change
    add_index :shots, :start_time
    add_index :shots, :user_id
    remove_index :shots, %i[user_id start_time]
  end
end
