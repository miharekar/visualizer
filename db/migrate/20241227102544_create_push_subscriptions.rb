class CreatePushSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :push_subscriptions, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :endpoint
      t.string :p256dh_key
      t.string :auth_key
      t.string :user_agent

      t.timestamps
    end
  end
end
