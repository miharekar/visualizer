require "test_helper"

module Parsers
  class GaggimateTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end

    test "extracts gaggimate v1 shot file" do
      shot = new_shot("test/files/gaggimate-v1.json")
      assert shot.valid?
      assert_equal "Parsers::Gaggimate", shot.information.brewdata["parser"]
      assert_equal "Blooming Espresso", shot.profile_title
      assert_equal "2025-07-18 11:41:51", shot.start_time.to_fs(:db)
      assert_equal 213, shot.information.timeframe.size
      assert_in_delta(0.88, shot.information.timeframe.first)
      assert_in_delta(22.823, shot.information.timeframe.last)
      assert_in_delta(22.823, shot.duration)
      expected_keys = Parsers::Gaggimate::DATA_LABELS_MAP.values
      assert_equal expected_keys.sort, shot.information.data.keys.sort
      assert_equal 213, shot.information.data["espresso_pressure"].size
      assert_in_delta(9.916, shot.information.data["espresso_flow"][2])
      assert_equal "81.73", shot.drink_weight
    end

    test "extracts gaggimate v0 shot file" do
      shot = new_shot("test/files/gaggimate-v0.json")
      assert shot.valid?
      assert_equal "Parsers::Gaggimate", shot.information.brewdata["parser"]
      assert_equal "Default", shot.profile_title
      assert_equal "2025-07-26 14:08:25", shot.start_time.to_fs(:db)
      assert_operator shot.information.timeframe.size, :>, 0
      assert_in_delta(0.866, shot.information.timeframe.first)
      expected_keys = Parsers::Gaggimate::DATA_LABELS_MAP.values
      assert_equal expected_keys.sort, shot.information.data.keys.sort
      assert_equal shot.information.timeframe.size, shot.information.data["espresso_pressure"].size
      assert_equal "238.54", shot.drink_weight
    end

    test "validates v1 data consistency" do
      shot = new_shot("test/files/gaggimate-v1.json")

      shot.information.data.each do |key, values|
        assert_equal shot.information.timeframe.size, values.size, "#{key} array size mismatch"
      end
    end

    test "validates v0 data consistency" do
      shot = new_shot("test/files/gaggimate-v0.json")

      shot.information.data.each do |key, values|
        assert_equal shot.information.timeframe.size, values.size, "#{key} array size mismatch"
      end
    end

    test "validates ev scaling" do
      shot = new_shot("test/files/gaggimate-v1.json")
      original_ev = 0 # from JSON first sample (ev field)
      expected_scaled = original_ev / 10.0
      assert_in_delta(expected_scaled, shot.information.data["espresso_flow_weight"][0])

      # Test a non-zero ev value from later in the shot
      # From the JSON, sample at index 7 has ev: 4.2
      expected_scaled_later = 4.2 / 10.0
      assert_in_delta(expected_scaled_later, shot.information.data["espresso_flow_weight"][7])
    end
  end
end
