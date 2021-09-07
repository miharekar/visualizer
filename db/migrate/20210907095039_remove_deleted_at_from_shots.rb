# frozen_string_literal: true

class RemoveDeletedAtFromShots < ActiveRecord::Migration[6.1]
  def change
    remove_column :shots, :deleted_at, :datetime
  end
end
