class CreateCustomers < ActiveRecord::Migration[7.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.references :user, foreign_key: true, type: :uuid
      t.string :stripe_id, index: true
      t.string :name
      t.string :email
      t.integer :amount
      t.jsonb :address
      t.jsonb :payments
      t.jsonb :refunds
    end
  end
end
