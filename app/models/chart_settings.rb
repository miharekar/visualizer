class ChartSettings
  DEFAULT = {
    "espresso_pressure" => {"title" => "Pressure", "color" => "#05c793", "suffix" => " bar", "type" => "spline"},
    "espresso_pressure_goal" => {"title" => "Pressure Goal", "color" => "#03634a", "suffix" => " bar", "dashed" => true, "type" => "spline"},
    "espresso_water_dispensed" => {"title" => "Water Dispensed", "color" => "#1fb7ea", "suffix" => " ml", "hidden" => true, "type" => "spline"},
    "espresso_weight" => {"title" => "Weight", "color" => "#8f6400", "suffix" => " g", "hidden" => true, "type" => "spline"},
    "espresso_flow" => {"title" => "Flow", "color" => "#1fb7ea", "suffix" => " ml/s", "type" => "spline"},
    "espresso_flow_weight" => {"title" => "Weight Flow", "color" => "#8f6400", "suffix" => " g/s", "type" => "spline"},
    "espresso_flow_goal" => {"title" => "Flow Goal", "color" => "#09485d", "suffix" => " ml/s", "dashed" => true, "type" => "spline"},
    "espresso_resistance" => {"title" => "Resistance", "color" => "#e5e500", "suffix" => " lΩ", "hidden" => true, "type" => "spline"},
    "espresso_conductance" => {"title" => "Conductance", "color" => "#f36943", "suffix" => "", "hidden" => true, "dashed" => true, "type" => "spline"},
    "espresso_conductance_derivative" => {"title" => "Conductance Derivative", "color" => "#f36943", "suffix" => "", "hidden" => true, "type" => "spline"},
    "espresso_temperature_basket" => {"title" => "Temperature Basket", "color" => "#EE7733", "suffix" => " °C", "type" => "spline"},
    "espresso_temperature_mix" => {"title" => "Temperature Mix", "color" => "#CC3311", "suffix" => " °C", "type" => "spline"},
    "espresso_temperature_goal" => {"title" => "Temperature Goal", "color" => "#EE3377", "suffix" => " °C", "dashed" => true, "type" => "spline"}
  }.freeze

  attr_reader :user_settings, :wants_fahrenheit

  def initialize(user = nil)
    @user_settings = user&.chart_settings.presence || {}
    @wants_fahrenheit = user&.wants_fahrenheit?
  end

  def for_label(label)
    return for_comparison(label) if label.end_with?(ShotChartCompare::SUFFIX)

    setting = DEFAULT[label]
    return if setting.blank?

    user_setting = user_settings[label]
    return setting if user_setting.blank?

    user_setting["suffix"] = " °F" if label.include?("temperature") && wants_fahrenheit
    setting.merge(user_setting)
  end

  private

  def for_comparison(label)
    og_label = label.sub(ShotChartCompare::SUFFIX, "")
    og_setting = for_label(og_label)
    return unless og_setting

    og_setting.merge("opacity" => 0.6, "title" => "#{og_setting["title"]} Comparison")
  end
end
