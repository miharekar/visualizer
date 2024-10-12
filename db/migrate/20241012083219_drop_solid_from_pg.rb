class DropSolidFromPg < ActiveRecord::Migration[8.0]
  def change
    drop_table :solid_cable_messages
    drop_table :solid_cache_entries
  end
end
