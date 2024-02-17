# frozen_string_literal: true

class AddDecentTokenToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :decent_email, :string
    add_column :users, :decent_token, :string
  end
end
