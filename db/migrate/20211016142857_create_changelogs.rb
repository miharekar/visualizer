# frozen_string_literal: true

class CreateChangelogs < ActiveRecord::Migration[7.0]
  def change
    create_table :changelogs, id: :uuid do |t|
      t.string :title
      t.text :body
      t.datetime :published_at

      t.timestamps
    end
  end
end
