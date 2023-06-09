# frozen_string_literal: true

class AddLastTransactionToAirtableInfo < ActiveRecord::Migration[7.0]
  def change
    add_column :airtable_infos, :last_transaction, :integer
  end
end
