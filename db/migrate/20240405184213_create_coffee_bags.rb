class CreateCoffeeBags < ActiveRecord::Migration[7.1]
  def change
    create_table :coffee_bags, id: :uuid do |t|
      t.references :roaster, null: false, foreign_key: true, type: :uuid
      t.string :name
      t.date :roast_date
      t.string :roast_level
      t.string :country
      t.string :region
      t.string :farm
      t.string :farmer
      t.string :variety
      t.string :elevation
      t.string :processing
      t.string :harvest_time
      t.string :quality_score

      t.timestamps
    end
  end
end
