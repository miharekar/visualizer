# frozen_string_literal: true

class AddShaToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :sha, :string
    add_index :shots, :sha
  end
end
