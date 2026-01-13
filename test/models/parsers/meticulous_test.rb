require "test_helper"

module Parsers
  class MeticulousTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end

    test "extracts meticulous shot file" do
      shot = new_shot("test/files/meticulous.shot.json")
      assert shot.valid?
      assert_equal "Parsers::Meticulous", shot.information.brewdata["parser"]
      assert_equal "Adaptive v1", shot.profile_title
      assert_equal "2025-12-30 17:36:18", shot.start_time.to_fs(:db)
      assert_equal 204, shot.information.timeframe.size
      assert_in_delta(0.004, shot.information.timeframe.first)
      assert_in_delta(26.278, shot.information.timeframe.last)
      expected_keys = %w[espresso_pressure espresso_flow espresso_weight espresso_flow_weight espresso_pressure_goal espresso_flow_goal espresso_temperature_mix espresso_state_change]
      assert_equal expected_keys.sort, shot.information.data.keys.sort
      assert_equal 204, shot.information.data["espresso_pressure"].size
      assert_in_delta(0.0, shot.information.data["espresso_pressure"].first)
      assert_in_delta(3.24, shot.information.data["espresso_flow"].first)
      assert_in_delta(88.69, shot.information.data["espresso_temperature_mix"].first)
      assert_equal "Prefill", shot.information.data["espresso_state_change"].first
    end

    test "validates data consistency" do
      shot = new_shot("test/files/meticulous.shot.json")

      shot.information.data.each do |key, values|
        assert_equal shot.information.timeframe.size, values.size, "#{key} array size mismatch"
      end
    end

    test "extracts stage changes from status field" do
      shot = new_shot("test/files/meticulous.shot.json")
      statuses = shot.information.data["espresso_state_change"].uniq
      assert_includes statuses, "Prefill"
    end
  end
end
