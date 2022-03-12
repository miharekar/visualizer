# frozen_string_literal: true

class CreateCoffees < ActiveRecord::Migration[7.0]
  def change
    create_table :coffees, id: :uuid do |t|
      t.string :roaster
      t.string :name
      t.string :country
      t.string :region
      t.string :variety
      t.string :process
      t.string :producer
      t.string :altitude

      t.timestamps
    end
  end
end
