require "test_helper"

module Parsers
  class GaggiuinoTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end

    test "extracts gaggiuino shot file" do
      shot = new_shot("test/files/gaggiuino-1020.json")
      assert shot.valid?
      assert_equal "Parsers::Gaggiuino", shot.information.brewdata["parser"]
      assert_equal "Zer0", shot.profile_title
      assert_equal "2024-10-09 06:39:30", shot.start_time.to_fs(:db)
      assert_equal 279, shot.information.timeframe.size
      assert_in_delta(0.2, shot.information.timeframe.first)
      assert_in_delta(42.2, shot.information.timeframe.last)
      assert_in_delta(42.2, shot.duration)
      assert_equal Parsers::Gaggiuino::DATA_LABELS_MAP.values.sort, shot.information.data.keys.sort
      assert_equal 279, shot.information.data["espresso_pressure"].size
    end
  end
end
