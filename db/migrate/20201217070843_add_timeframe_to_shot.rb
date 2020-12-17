# frozen_string_literal: true

class AddTimeframeToShot < ActiveRecord::Migration[6.1]
  def change
    add_column :shots, :timeframe, :jsonb
  end
end
