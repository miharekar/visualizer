class AddAirtableIdToRoasters < ActiveRecord::Migration[7.1]
  def change
    add_column :roasters, :airtable_id, :string
    add_index :roasters, :airtable_id
  end
end
