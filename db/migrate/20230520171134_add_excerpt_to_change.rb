# frozen_string_literal: true

class AddExcerptToChange < ActiveRecord::Migration[7.0]
  def change
    add_column :changes, :excerpt, :string
  end
end
