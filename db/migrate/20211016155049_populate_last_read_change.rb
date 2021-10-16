# frozen_string_literal: true

class PopulateLastReadChange < ActiveRecord::Migration[7.0]
  class MigrationUser < ApplicationRecord
    self.table_name = :users
  end

  def up
    MigrationUser.update_all(last_read_change: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end
end
