# frozen_string_literal: true

class AddOwnerToApplication < ActiveRecord::Migration[7.0]
  def change
    add_column :oauth_applications, :owner_id, :uuid, null: false
    add_column :oauth_applications, :owner_type, :string, null: false
    add_index :oauth_applications, %i[owner_id owner_type]
  end
end
