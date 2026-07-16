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

  test "it shows separate basket and mix temperature goals" do
    payload = JSON.parse(File.read("test/files/20211019T100744.json"))
    payload["temperature"]["mix_goal"] = payload.dig("temperature", "goal").map { |value| value.to_f + 2 }
    shot = Shot.from_file(build_stubbed(:user), JSON.generate(payload))

    series = ShotChart.new(shot, build_stubbed(:user)).temperature_chart
    basket_goal = series.find { |item| item[:name] == "Basket Temperature Goal" }
    mix_goal = series.find { |item| item[:name] == "Mix Temperature Goal" }

    assert_not_nil basket_goal
    assert_not_nil mix_goal
    assert_equal "Dash", basket_goal[:dashStyle]
    assert_equal "Dash", mix_goal[:dashStyle]
  end
end
