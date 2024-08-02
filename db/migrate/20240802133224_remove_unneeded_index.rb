class RemoveUnneededIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :roasters, name: :index_roasters_on_user_id, column: :user_id
  end
end
