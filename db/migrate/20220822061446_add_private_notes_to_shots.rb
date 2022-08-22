# frozen_string_literal: true

class AddPrivateNotesToShots < ActiveRecord::Migration[7.0]
  def change
    add_column :shots, :private_notes, :text
  end
end
