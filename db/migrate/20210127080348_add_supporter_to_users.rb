# frozen_string_literal: true

class AddSupporterToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :supporter, :boolean # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
