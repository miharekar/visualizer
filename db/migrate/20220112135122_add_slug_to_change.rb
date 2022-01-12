# frozen_string_literal: true

class AddSlugToChange < ActiveRecord::Migration[7.0]
  def change
    add_column :changes, :slug, :string
    add_index :changes, :slug, unique: true
  end
end
