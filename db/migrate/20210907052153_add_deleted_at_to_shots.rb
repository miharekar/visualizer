# frozen_string_literal: true

class AddDeletedAtToShots < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :deleted_at, :datetime
  end
end
