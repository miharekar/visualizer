# frozen_string_literal: true

class CreateRoasters < ActiveRecord::Migration[7.0]
  def change
    create_table :roasters, id: :uuid do |t|
      t.string :name
      t.string :website
      t.string :country

      t.timestamps
    end
  end
end
