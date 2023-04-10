# frozen_string_literal: true

class CreateIdentities < ActiveRecord::Migration[7.0]
  def change
    create_table :identities, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.jsonb :blob
      t.datetime :expires_at
      t.string :provider
      t.string :uid
      t.string :token
      t.string :refresh_token

      t.index %i[provider uid], unique: true

      t.timestamps
    end
  end
end
