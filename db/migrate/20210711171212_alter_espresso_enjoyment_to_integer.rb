# frozen_string_literal: true

class AlterEspressoEnjoymentToInteger < ActiveRecord::Migration[6.1]
  class MigrationShot < ApplicationRecord
    self.table_name = :shots
  end

  def up
    problematic = MigrationShot.where.not(espresso_enjoyment: nil).pluck(:id, :espresso_enjoyment).reject { |_id, e| e.to_i.to_s == e }
    MigrationShot.where(id: problematic.map(&:first)).each do |shot|
      shot.update(espresso_enjoyment: shot.espresso_enjoyment.to_i)
    end

    change_column :shots, :espresso_enjoyment, :integer, using: "espresso_enjoyment::integer"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
