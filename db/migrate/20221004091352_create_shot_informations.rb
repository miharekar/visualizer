# frozen_string_literal: true

class CreateShotInformations < ActiveRecord::Migration[7.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :shot_informations, id: :uuid do |t|
      t.references :shot, null: false, foreign_key: true, type: :uuid
      t.jsonb :data
      t.jsonb :extra
      t.jsonb :profile_fields
      t.jsonb :timeframe
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
