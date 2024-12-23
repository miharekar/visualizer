class DropDuplicatedIndexesOnTags < ActiveRecord::Migration[8.0]
  def change
    remove_index :shot_tags, name: "index_shot_tags_on_tag_id", column: :tag_id
    remove_index :tags, name: "index_tags_on_user_id", column: :user_id
  end
end
