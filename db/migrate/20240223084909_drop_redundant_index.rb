# frozen_string_literal: true

class DropRedundantIndex < ActiveRecord::Migration[7.1]
  def change
    remove_index :shots, %i[user_id created_at]
  end
end
