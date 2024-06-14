class AddMultipleTableSupportToAirtableInfo < ActiveRecord::Migration[7.1]
  def change
    add_column :airtable_infos, :tables, :jsonb
    remove_column :airtable_infos, :table_id, :string
    remove_column :airtable_infos, :table_fields, :jsonb
    remove_column :airtable_infos, :last_cursor, :integer
    remove_column :airtable_infos, :last_transaction, :integer
  end
end
