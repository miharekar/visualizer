# frozen_string_literal: true

class AddDeveloperToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :developer, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
