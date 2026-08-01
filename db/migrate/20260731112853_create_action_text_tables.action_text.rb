# This migration comes from action_text (originally 20180528164100)
class CreateActionTextTables < ActiveRecord::Migration[8.1]
  def change
    create_table :action_text_rich_texts, id: :uuid do |t|
      t.string :name, null: false
      t.text :body
      t.references :record, null: false, polymorphic: true, index: false, type: :uuid
      t.timestamps

      t.index %i[record_type record_id name], name: "index_action_text_rich_texts_uniqueness", unique: true
    end
  end
end
