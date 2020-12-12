# frozen_string_literal: true

class AddProfileTitleToShots < ActiveRecord::Migration[6.0]
  def change
    add_column :shots, :profile_title, :string
  end
end
