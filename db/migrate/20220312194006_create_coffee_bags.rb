# frozen_string_literal: true

class CreateCoffeeBags < ActiveRecord::Migration[7.0]
  def change
    create_table :coffee_bags, id: :uuid do |t|
      t.references :coffee, null: false, foreign_key: true, type: :uuid
      t.date :roast_date
      t.string :level
      t.string :harvest
      t.string :quality

      t.timestamps
    end
  end
end
