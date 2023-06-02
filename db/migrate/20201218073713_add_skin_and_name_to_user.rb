# frozen_string_literal: true

class AddSkinAndNameToUser < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :skin, :string
    add_column :users, :name, :string
    add_column :users, :public, :boolean, default: false # rubocop:disable Rails/ThreeStateBooleanColumn
  end
end
