# frozen_string_literal: true

class AddSuggestedIndexes < ActiveRecord::Migration[7.0]
  def change
    add_index :shots, [:created_at]
    add_index :shots, %i[user_id created_at]
    add_index :shots, %i[user_id start_time]
  end
end
