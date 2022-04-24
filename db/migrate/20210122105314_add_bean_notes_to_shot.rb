# frozen_string_literal: true

class AddBeanNotesToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :bean_notes, :text
  end
end
