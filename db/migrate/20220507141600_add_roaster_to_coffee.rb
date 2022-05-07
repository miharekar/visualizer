# frozen_string_literal: true

class AddRoasterToCoffee < ActiveRecord::Migration[7.0]
  def change
    remove_column :coffees, :roaster, :string
    add_reference :coffees, :roaster, null: true, foreign_key: true, type: :uuid
  end
end
