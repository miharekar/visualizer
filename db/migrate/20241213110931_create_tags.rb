class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags, id: :uuid do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :tags, [:user_id, :slug], unique: true
  end
end
