class CreateJoinTableShotsTags < ActiveRecord::Migration[8.0]
  def change
    create_join_table :shot, :tags do |t|
      t.index [:tag_id, :shot_id], unique: true
    end
  end
end
