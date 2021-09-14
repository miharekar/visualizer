# frozen_string_literal: true

class PopulateChartSettings < ActiveRecord::Migration[7.0]
  class MigrationUser < ApplicationRecord
    self.table_name = :users
  end

  def up
    MigrationUser.find_each do |user|
      skin = ShotChart::SKIN_SETTINGS[user.skin.present? ? user.skin.split.last : "Classic"]
      chart_settings = {}
      ShotChart::LABELS.each do |label|
        properties = skin[label]
        label_settings = {type: "none", hidden: false}
        if properties
          label_settings = label_settings.merge(properties.slice(:color, :type, :dashed, :hidden))
        else
          label_settings[:hidden] = true
        end
        chart_settings[label] = label_settings
      end
      user.update_columns(chart_settings: chart_settings)
    end
  end
end
