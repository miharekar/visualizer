# frozen_string_literal: true

class RemoveUnneededIndexes < ActiveRecord::Migration[7.0]
  def change
    remove_index :shots, name: "index_shots_on_user_id", column: :user_id
  end
end
