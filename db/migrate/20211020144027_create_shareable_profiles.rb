# frozen_string_literal: true

class CreateShareableProfiles < ActiveRecord::Migration[7.0]
  def change
    create_table :shareable_profiles, id: :uuid do |t|
      t.references :shot, null: false, foreign_key: true, type: :uuid
      t.string :code, null: false
      t.index :code, unique: true

      t.timestamps
    end
  end
end
