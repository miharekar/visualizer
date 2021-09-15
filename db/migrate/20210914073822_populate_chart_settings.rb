# frozen_string_literal: true

class PopulateChartSettings < ActiveRecord::Migration[7.0]
  SKIN_SETTINGS = {
    "Classic" => {
      "espresso_pressure" => {color: "#05c793", type: "spline"},
      "espresso_pressure_goal" => {color: "#03634a", dashed: true, type: "spline"},
      "espresso_water_dispensed" => {color: "#1fb7ea", hidden: true, type: "spline"},
      "espresso_weight" => {color: "#8f6400", hidden: true, type: "spline"},
      "espresso_flow" => {color: "#1fb7ea", type: "spline"},
      "espresso_flow_weight" => {color: "#8f6400", type: "spline"},
      "espresso_flow_goal" => {color: "#09485d", dashed: true, type: "spline"},
      "espresso_resistance" => {color: "#e5e500", hidden: true, type: "spline"},
      "espresso_temperature_basket" => {color: "#e73249", type: "spline"},
      "espresso_temperature_mix" => {color: "#ce123e", type: "spline"},
      "espresso_temperature_goal" => {color: "#960d2d", dashed: true, type: "spline"}
    },
    "DSx" => {
      "espresso_pressure" => {color: "#18c37e", suffix: " bar"},
      "espresso_pressure_goal" => {color: "#69fdb3", dashed: true},
      "espresso_weight" => {color: "#a2693d", hidden: true},
      "espresso_flow" => {color: "#4e85f4", suffix: " ml/s"},
      "espresso_flow_weight" => {color: "#a2693d", suffix: " g/s"},
      "espresso_flow_goal" => {color: "#7aaaff", dashed: true},
      "espresso_resistance" => {color: "#e5e500", hidden: true},
      "espresso_temperature_basket" => {color: "#e73249", suffix: " °C"},
      "espresso_temperature_mix" => {color: "#ff9900", suffix: " °C"},
      "espresso_temperature_goal" => {color: "#e73249", dashed: true}
    }
  }.freeze

  class MigrationUser < ApplicationRecord
    self.table_name = :users
  end

  def up
    MigrationUser.find_each do |user|
      skin = SKIN_SETTINGS[user.skin.present? ? user.skin.split.last : "Classic"]
      chart_settings = {}
      ShotChart::CHART_SETTINGS.each_key do |label|
        properties = skin[label]
        label_settings = {type: "none", hidden: false}
        if properties
          label_settings = label_settings.merge(properties.slice(:color, :type, :dashed, :hidden))
        else
          label_settings[:hidden] = true
        end
        chart_settings[label] = label_settings
      end

      user.update_columns(
        chart_settings: chart_settings,
        skin: user.skin == "DSx" ? "Dark" : "Light"
      )
    end
  end

  def down
    MigrationUser.find_each do |user|
      user.update_columns(
        skin: user.skin == "Dark" ? "DSx" : "Classic"
      )
    end
  end
end
