# frozen_string_literal: true

class CreateShots < ActiveRecord::Migration[6.0]
  def change
    create_table :shots, id: :uuid do |t|
      t.datetime :start_time
      t.jsonb :data

      t.timestamps
    end
  end
end
