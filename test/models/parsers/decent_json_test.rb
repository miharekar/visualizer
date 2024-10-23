require "test_helper"

module Parsers
  class DecentJsonTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end
    test "extracts fields from .json upload file and replaces content when .shot of same shot" do
      @user = create(:user, :public)

      path = "test/files/20211019T100744"
      shot = new_shot("#{path}.json")
      assert_equal @user, shot.user
      assert shot.public
      assert_equal "Easy blooming - active pressure decline", shot.profile_title
      assert_equal "2021-10-19 08:07:44", shot.start_time.to_fs(:db)
      assert_equal "Parsers::DecentJson", shot.information.brewdata["parser"]
      assert_equal 109, shot.information.timeframe.size
      assert_equal "0.044", shot.information.timeframe.first
      assert_equal "26.999", shot.information.timeframe.last
      assert_in_delta(26.999, shot.duration)
      assert_equal Parsers::DecentTcl::DATA_LABELS.sort, shot.information.data.keys.sort
      assert_equal 110, shot.information.data["espresso_pressure"].size
      assert_equal 19, shot.information.extra.keys.size
      assert_equal 46, shot.information.profile_fields.keys.size
      assert_equal "42.6", shot.drink_weight
      assert_equal "EK43 with SSP HU", shot.grinder_model
      assert_equal "2.4", shot.grinder_setting
      assert_equal "BeBerry", shot.bean_brand
      assert_equal "Shantawene", shot.bean_type
      assert_nil shot.roast_level
      assert_equal "05.10.2021", shot.roast_date
      assert_equal "0", shot.drink_tds
      assert_equal "0", shot.drink_ey
      assert_equal 0, shot.espresso_enjoyment
      assert_nil shot.espresso_notes
      assert_equal "With BPlus", shot.bean_notes
      assert_equal "Miha Rekar", shot.information.extra["my_name"]
      assert_equal "Miha Rekar", shot.barista
      assert_equal "MimojaCafe", shot.information.extra["skin"]
      assert_equal "4567", shot.information.extra["sn"]
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      assert_equal File.read("#{path}.json_profile"), shot.information.json_profile
      assert_equal File.read("#{path}.csv"), shot.information.csv_profile

      shot.save!
      old_id = shot.id
      shot = new_shot("#{path}.shot")
      shot.save!
      assert_equal old_id, shot.id

      assert_equal @user, shot.user
      assert_equal "Easy blooming - active pressure decline", shot.profile_title
      assert_equal "2021-10-19 08:07:44", shot.start_time.to_fs(:db)
      assert_equal "Parsers::DecentTcl", shot.information.brewdata["parser"]
      assert_equal 109, shot.information.timeframe.size
      assert_equal "0.044", shot.information.timeframe.first
      assert_equal "26.999", shot.information.timeframe.last
      assert_in_delta(26.999, shot.duration)
      assert_equal Parsers::DecentTcl::DATA_LABELS.sort, shot.information.data.keys.sort
      assert_equal 110, shot.information.data["espresso_pressure"].size
      assert_equal 16, shot.information.extra.keys.size
      assert_equal 46, shot.information.profile_fields.keys.size
      assert_equal "42.6", shot.drink_weight
      assert_equal "EK43 with SSP HU", shot.grinder_model
      assert_equal "2.4", shot.grinder_setting
      assert_equal "BeBerry", shot.bean_brand
      assert_equal "Shantawene", shot.bean_type
      assert_nil shot.roast_level
      assert_equal "05.10.2021", shot.roast_date
      assert_equal "0", shot.drink_tds
      assert_equal "0", shot.drink_ey
      assert_equal 80, shot.espresso_enjoyment
      assert_nil shot.espresso_notes
      assert_equal "With BPlus", shot.bean_notes
      assert_equal "Miha Rekar", shot.information.extra["my_name"]
      assert_equal "Miha Rekar", shot.barista
      assert_equal "MimojaCafe", shot.information.extra["skin"]
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      assert_equal File.read("#{path}.json_profile"), shot.information.json_profile
    end

    test "handles invalid profile string" do
      shot = new_shot("test/files/invalid_profile.json")
      assert shot.valid?
      assert_equal "phaad/Extractamundo Dos!", shot.profile_title
      assert_equal 101, shot.information.timeframe.size
    end

    test "handles even more invalid profile string" do
      shot = new_shot("test/files/invalid_profile_2.json")
      assert shot.valid?
      assert_equal "fill brew release", shot.profile_title
      assert_equal 237, shot.information.timeframe.size
    end

    test "handles invalid settings" do
      shot = new_shot("test/files/invalid_settings.json")
      assert shot.valid?
      assert_equal "HELLCAFE Synesso mvp", shot.profile_title
      assert_equal 145, shot.information.timeframe.size
    end

    test "handles very invalid settings" do
      shot = new_shot("test/files/very_invalid_settings.json")
      assert shot.valid?
      assert_equal "Visualizer/Filter 2.0.2 15 in 18 1:4-5", shot.profile_title
      assert_equal 679, shot.information.timeframe.size
    end

    test "handles invalid file" do
      shot = new_shot("test/files/invalid_file.something")
      assert_not shot.valid?
    end

    test "handles pyde1 fake tcl file" do
      shot = new_shot("test/files/pyde.faketcl")
      assert shot.valid?
      assert_equal "Extractamundo Dos!", shot.profile_title
      assert_equal 98, shot.information.timeframe.size
    end

    test "handles empty instructions inside advanced_shot" do
      shot = new_shot("test/files/empty_flow.shot")
      assert shot.valid?
      assert_equal "6BarFlat", shot.profile_title
      assert_equal 80, shot.information.timeframe.size
    end

    test "extracts newlines in bean notes from .shot file" do
      shot = new_shot("test/files/20240202T063530.shot")
      assert shot.valid?
      assert_equal "- chocolate\n- woodsy\n- smooth", shot.bean_notes
    end
  end
end
