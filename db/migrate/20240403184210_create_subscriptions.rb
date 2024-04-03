class CreateSubscriptions < ActiveRecord::Migration[7.1]
  def change
    create_table :subscriptions, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :stripe_id, index: true
      t.string :status
      t.string :interval
      t.datetime :started_at
      t.datetime :ended_at
      t.datetime :cancel_at
      t.datetime :cancelled_at
    end
  end
end
