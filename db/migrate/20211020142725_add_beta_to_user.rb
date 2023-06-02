# frozen_string_literal: true

class AddBetaToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :beta, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
