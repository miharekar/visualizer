class CreateCanonicalRoasters < ActiveRecord::Migration[8.0]
  def change
    create_table :canonical_roasters, id: :uuid do |t|
      t.string :name
      t.string :website
      t.string :country
      t.string :address
      t.string :loffee_labs_id

      t.timestamps
    end
  end
end
