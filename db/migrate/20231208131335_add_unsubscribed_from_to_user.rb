# frozen_string_literal: true

class AddUnsubscribedFromToUser < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :unsubscribed_from, :jsonb
  end
end
