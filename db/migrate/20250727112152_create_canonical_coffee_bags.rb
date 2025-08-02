class CreateCanonicalCoffeeBags < ActiveRecord::Migration[8.0]
  def change
    create_table :canonical_coffee_bags, id: :uuid do |t|
      t.references :canonical_roaster, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.string :url
      t.string :country
      t.string :region
      t.string :elevation
      t.string :farmer
      t.string :harvest_time
      t.string :processing
      t.string :roast_level
      t.string :variety
      t.string :tasting_notes
      t.string :loffee_labs_id

      t.timestamps
    end
  end
end
