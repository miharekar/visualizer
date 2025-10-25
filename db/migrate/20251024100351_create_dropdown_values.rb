class CreateDropdownValues < ActiveRecord::Migration[8.1]
  def change
    create_table :dropdown_values, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :kind
      t.string :value
      t.timestamp :hidden_at

      t.timestamps
    end
    add_index :dropdown_values, [:user_id, :kind, :value], unique: true
  end
end
