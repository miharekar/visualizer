require "test_helper"

class ShotChartTest < ActiveSupport::TestCase
  def shot_from_fixture(path = "test/files/meticulous.shot.json")
    Shot.from_file(build_stubbed(:user), File.read(path))
  end

  test "it keeps temperature series separate by default" do
    chart = ShotChart.new(shot_from_fixture, build_stubbed(:user))

    assert_includes chart.shot_chart.pluck(:name), "Pressure"
    assert_not_includes chart.shot_chart.pluck(:name), "Temperature Mix"
    assert_includes chart.temperature_chart.pluck(:name), "Temperature Mix"
  end

  test "it can show temperature on the main chart" do
    user = build_stubbed(:user, unified_chart: true)
    chart = ShotChart.new(shot_from_fixture, user)

    temperature_series = chart.shot_chart.find { |series| series[:name] == "Temperature Mix" }

    assert_not_nil temperature_series
    assert_equal 1, temperature_series[:yAxis]
    assert_empty chart.temperature_chart
  end

  test "comparison data still includes temperature when combined" do
    user = build_stubbed(:user, unified_chart: true)
    chart = ShotChartCompare.new(shot_from_fixture, shot_from_fixture, user)

    assert_includes chart.comparison_data.keys, "Temperature Mix Comparison"
  end

  test "temperature chart tooltip uses fahrenheit suffix for fahrenheit users" do
    user = build_stubbed(:user, temperature_unit: "Fahrenheit")
    chart = ShotChart.new(shot_from_fixture, user)

    temperature_series = chart.temperature_chart.find { |series| series[:name] == "Temperature Mix" }

    assert_not_nil temperature_series
    assert_equal " °F", temperature_series.dig(:tooltip, :valueSuffix)
  end
end
