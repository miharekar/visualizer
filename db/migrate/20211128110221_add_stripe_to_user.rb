class AddStripeToUser < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :stripe_session_id, :string
    add_column :users, :premium, :boolean
  end
end
