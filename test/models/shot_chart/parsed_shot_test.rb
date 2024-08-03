require "test_helper"

class ParsedShotTest < ActiveSupport::TestCase
  test "it parses real beanconqueror correctly" do
    shot = Shot.from_file(build_stubbed(:user), File.read("test/files/beanconqueror_real.json"))
    assert_equal 1, shot.information.timeframe.count
    assert shot.information.data.blank?

    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_equal 488, parsed_shot.timeframe.size
    assert_equal "0.0", parsed_shot.timeframe.first
    assert_equal "34.858", parsed_shot.timeframe.last
    assert_equal %w[espresso_flow espresso_flow_weight espresso_pressure espresso_weight], parsed_shot.data.keys.sort
    assert_equal 488, parsed_shot.data["espresso_weight"].size
  end

  test "it parses long beanconqueror file with negative values correctly" do
    shot = Shot.from_file(build_stubbed(:user), File.read("test/files/beanconqueror_negative.json"))
    assert_equal 1, shot.information.timeframe.count
    assert shot.information.data.blank?

    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_equal 1748, parsed_shot.timeframe.size
    assert_equal "0.0", parsed_shot.timeframe.first
    assert_equal "174.244", parsed_shot.timeframe.last
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], parsed_shot.data.keys.sort
    assert_equal 1748, parsed_shot.data["espresso_weight"].size
    assert parsed_shot.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "it parses long beanconqueror file with missing values correctly" do
    shot = Shot.from_file(build_stubbed(:user), File.read("test/files/beanconqueror_missing_values.json"))
    assert_equal 1, shot.information.timeframe.count
    assert shot.information.data.blank?

    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_equal 1366, parsed_shot.timeframe.size
    assert_equal "0.0", parsed_shot.timeframe.first
    assert_equal "147.542", parsed_shot.timeframe.last
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], parsed_shot.data.keys.sort
    assert_equal 1366, parsed_shot.data["espresso_weight"].size
    assert parsed_shot.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "it parses correct weight from beanconqueror" do
    shot = Shot.from_file(build_stubbed(:user), File.read("test/files/beanconqueror_beverage_weight.json"))
    assert_equal 1, shot.information.timeframe.count
    assert shot.information.data.blank?

    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_equal 1117, parsed_shot.timeframe.size
    assert_equal "0.0", parsed_shot.timeframe.first
    assert_equal "163.198", parsed_shot.timeframe.last
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], parsed_shot.data.keys.sort
    assert_equal 1117, parsed_shot.data["espresso_weight"].size
    assert parsed_shot.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "it parses beanconqueror temperature file correctly" do
    shot = Shot.from_file(build_stubbed(:user), File.read("test/files/beanconqueror_temperature.json"))
    assert_equal 1, shot.information.timeframe.count
    assert shot.information.data.blank?

    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_equal 147, parsed_shot.timeframe.size
    assert_equal "0.0", parsed_shot.timeframe.first
    assert_equal "17.198", parsed_shot.timeframe.last
    assert_equal %w[espresso_flow espresso_flow_weight espresso_temperature_mix espresso_weight], parsed_shot.data.keys.sort
    assert_equal 147, parsed_shot.data["espresso_weight"].size
  end

  test "fahrenheit? should return true only if extra enable_fahrenheit is 1" do
    shot = build_stubbed(:shot, :with_information, information: build_stubbed(:shot_information, extra: {enable_fahrenheit: 1}))
    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert parsed_shot.fahrenheit?

    shot = build_stubbed(:shot, :with_information, information: build_stubbed(:shot_information, extra: {enable_fahrenheit: "1"}))
    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert parsed_shot.fahrenheit?

    shot = build_stubbed(:shot, :with_information, information: build_stubbed(:shot_information, extra: {enable_fahrenheit: 0}))
    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_not parsed_shot.fahrenheit?

    shot = build_stubbed(:shot, :with_information, information: build_stubbed(:shot_information, extra: {enable_fahrenheit: "0"}))
    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_not parsed_shot.fahrenheit?

    shot = build_stubbed(:shot, :with_information)
    parsed_shot = ShotChart::ParsedShot.new(shot)
    assert_not parsed_shot.fahrenheit?
  end
end
