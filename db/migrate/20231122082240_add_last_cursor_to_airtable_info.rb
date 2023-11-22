# frozen_string_literal: true

class AddLastCursorToAirtableInfo < ActiveRecord::Migration[7.1]
  def change
    add_column :airtable_infos, :last_cursor, :integer
  end
end
