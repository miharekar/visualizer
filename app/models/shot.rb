class Shot < ApplicationRecord
  CHART_CONFIG = {
    "espresso_pressure" => {title: "Pressure", border_color: "rgba(5, 199, 147, 1)", background_color: "rgba(5, 199, 147, 0.7)", border_dash: [], fill: true, hidden: false},
    "espresso_weight" => {title: "Weight", border_color: "rgba(143, 100, 0, 1)", background_color: "rgba(143, 100, 0, 0.7)", border_dash: [], fill: true, hidden: true},
    "espresso_flow" => {title: "Flow", border_color: "rgba(31, 183, 234, 1)", background_color: "rgba(31, 183, 234, 0.7)", border_dash: [], fill: true, hidden: false},
    "espresso_flow_weight" => {title: "Flow Weight", border_color: "rgba(17, 138, 178, 1)", background_color: "rgba(17, 138, 178, 0.7)", border_dash: [], fill: true, hidden: false},
    "espresso_temperature_basket" => {title: "Temperature Basket", border_color: "rgba(240, 86, 122, 1)", background_color: "rgba(240, 86, 122, 0.7)", border_dash: [], fill: false, hidden: false},
    "espresso_temperature_mix" => {title: "Temperature Mix", border_color: "rgba(206, 18, 62, 1)", background_color: "rgba(206, 18, 62, 0.7)", border_dash: [], fill: false, hidden: false},
    "espresso_water_dispensed" => {title: "Water Dispensed", border_color: "rgba(31, 183, 234, 1)", background_color: "rgba(31, 183, 234, 0.7)", border_dash: [], fill: true, hidden: false},
    "espresso_temperature_goal" => {title: "Temperature Goal", border_color: "rgba(150, 13, 45, 1)", background_color: "rgba(150, 13, 45, 0.7)", border_dash: [5, 5], fill: false, hidden: false},
    "espresso_flow_weight_raw" => {title: "Flow Weight Raw", border_color: "rgba(17, 138, 178, 1)", background_color: "rgba(17, 138, 178, 1)", border_dash: [], fill: false, hidden: false},
    "espresso_pressure_goal" => {title: "Pressure Goal", border_color: "rgba(3, 99, 74, 1)", background_color: "rgba(3, 99, 74, 1)", border_dash: [5, 5], fill: false, hidden: false},
    "espresso_flow_goal" => {title: "Flow Goal", border_color: "rgba(9, 72, 93, 1)", background_color: "rgba(9, 72, 93, 1)", border_dash: [5, 5], fill: false, hidden: false}
  }.freeze

  def chart_data
    timeframe = data.find { |d| d["label"] == "espresso_elapsed" }["data"]
    data.map do |d|
      next if !CHART_CONFIG.key?(d["label"]) || d["label"] == "espresso_elapsed"

      {
        label: CHART_CONFIG[d["label"]][:title],
        data: d["data"].map.with_index { |v, i| {t: timeframe[i].to_f * 1000, y: v} },
        borderColor: CHART_CONFIG[d["label"]][:border_color],
        backgroundColor: CHART_CONFIG[d["label"]][:background_color],
        borderDash: CHART_CONFIG[d["label"]][:border_dash],
        fill: CHART_CONFIG[d["label"]][:fill],
        hidden: CHART_CONFIG[d["label"]][:hidden],
        pointRadius: 0
      }
    end.compact
  end
end

# == Schema Information
#
# Table name: shots
#
#  id            :uuid             not null, primary key
#  data          :jsonb
#  profile_title :string
#  start_time    :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
