class AddCommunicationToUser < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :communication, :jsonb
  end
end
