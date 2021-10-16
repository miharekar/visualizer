# frozen_string_literal: true

class AddLastReadChangeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :last_read_change, :datetime
  end
end
