class CreateJoinTableShotsTags < ActiveRecord::Migration[8.0]
  def change
    create_table :shot_tags, id: false do |t|
      t.references :shot, null: false, foreign_key: true, type: :uuid
      t.references :tag, null: false, foreign_key: true, type: :uuid
    end
  end
end
