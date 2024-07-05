class AddAirtableIdToCoffeeBags < ActiveRecord::Migration[7.1]
  def change
    add_column :coffee_bags, :airtable_id, :string
    add_index :coffee_bags, :airtable_id
  end
end
