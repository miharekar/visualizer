class AddJournalPreferences < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :journal_enabled, :boolean, default: false, null: false
    add_column :users, :journal_columns, :jsonb
  end
end
