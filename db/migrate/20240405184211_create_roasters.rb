class CreateRoasters < ActiveRecord::Migration[7.1]
  def change
    create_table :roasters, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :website

      t.timestamps

      t.index %i[user_id name], unique: true
    end
  end
end
