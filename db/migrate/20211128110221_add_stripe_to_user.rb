# frozen_string_literal: true

class AddStripeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :stripe_customer_id, :string
    add_column :users, :premium_expires_at, :datetime
  end
end
