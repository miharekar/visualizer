# frozen_string_literal: true

class AddBaristaToShot < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :barista, :string
  end
end
