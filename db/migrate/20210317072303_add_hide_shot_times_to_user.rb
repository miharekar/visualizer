# frozen_string_literal: true

class AddHideShotTimesToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :hide_shot_times, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
