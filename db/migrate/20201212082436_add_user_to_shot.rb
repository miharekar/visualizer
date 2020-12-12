# frozen_string_literal: true

class AddUserToShot < ActiveRecord::Migration[6.1]
  def change
    add_reference :shots, :user, foreign_key: true, type: :uuid
  end
end
