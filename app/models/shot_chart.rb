class ShotChart
  prepend MemoWise
  include Process
  include AdditionalCharts

  attr_reader :parsed_shot, :user

  def initialize(shot, user = nil)
    @parsed_shot = ParsedShot.new(shot)
    @user = user
    prepare_chart_data
  end

  def data?
    shot_chart.present? || temperature_chart.present?
  end

  memo_wise def shot_chart
    for_highcharts(@processed_shot_data.sort.reject { |key, _v| key.include?("temperature") })
  end

  memo_wise def temperature_chart
    for_highcharts(@processed_shot_data.sort.select { |key, _v| key.include?("temperature") })
  end

  memo_wise def stages
    return if parsed_shot.stage_indices.blank?

    @processed_shot_data.first.second.values_at(*parsed_shot.stage_indices).compact.map { |d| {value: d.first} }
  end

  private

  def prepare_chart_data
    @processed_shot_data = process_data(parsed_shot)
    return if @processed_shot_data["espresso_pressure"].blank?

    @processed_shot_data["espresso_resistance"] = resistance_chart(@processed_shot_data["espresso_pressure"], @processed_shot_data["espresso_flow"]) if @processed_shot_data["espresso_pressure"].present? && @processed_shot_data["espresso_flow"].present?
    @processed_shot_data["espresso_conductance"] = conductance_chart(@processed_shot_data["espresso_pressure"], @processed_shot_data["espresso_flow"]) if @processed_shot_data["espresso_pressure"].present? && @processed_shot_data["espresso_flow"].present?
    @processed_shot_data["espresso_conductance_derivative"] = conductance_derivative_chart(@processed_shot_data["espresso_conductance"]) if @processed_shot_data["espresso_conductance"].present?
  end

  def for_highcharts(data)
    chart_settings = ChartSettings.new(user)
    data.filter_map do |label, d|
      setting = chart_settings.for_label(label)
      next if setting.blank?

      if setting["comparison"]
        dash_style = setting["dashed"] ? "DashDot" : "ShortDot"
      else
        dash_style = setting["dashed"] ? "Dash" : "Solid"
      end

      {
        name: setting["title"],
        data: d,
        color: setting["color"],
        visible: !setting["hidden"],
        dashStyle: dash_style,
        tooltip: {
          valueDecimals: 2,
          valueSuffix: setting["suffix"]
        },
        opacity: setting["opacity"] || 1,
        type: setting["type"] == "spline" ? "spline" : "line"
      }
    end
  end
end
