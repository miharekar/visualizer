# frozen_string_literal: true

class RenameCommentOnShot < ActiveRecord::Migration[6.1]
  def change
    rename_column :shots, :comment, :espresso_notes
  end
end
