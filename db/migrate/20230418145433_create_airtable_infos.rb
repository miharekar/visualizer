# frozen_string_literal: true

class CreateAirtableInfos < ActiveRecord::Migration[7.0]
  def change
    create_table :airtable_infos, id: :uuid do |t|
      t.references :identity, null: false, foreign_key: true, type: :uuid
      t.string :base_id
      t.string :table_id
      t.jsonb :table_fields
      t.string :webhook_id

      t.timestamps
    end
  end
end
