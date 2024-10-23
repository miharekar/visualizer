require "test_helper"

module Parsers
  class DecentTclTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end

    test "returns invalid Shot with empty file" do
      shot = Shot.from_file(@user, "")
      assert_not shot.valid?
    end

    test "extracts fields from .shot file" do
      path = "test/files/20210921T085910"
      shot = new_shot("#{path}.shot")
      assert_equal @user, shot.user
      assert_not shot.public
      assert_equal "JoeD's Easy blooming slow ramp to 7 bar", shot.profile_title
      assert_equal "2021-09-21 06:59:10", shot.start_time.to_fs(:db)
      assert_equal "Parsers::DecentTcl", shot.information.brewdata["parser"]
      assert_equal 100, shot.information.timeframe.size
      assert_equal "0.044", shot.information.timeframe.first
      assert_equal "24.793", shot.information.timeframe.last
      assert_in_delta(24.793, shot.duration)
      assert_equal Parsers::DecentTcl::DATA_LABELS.sort, shot.information.data.keys.sort
      assert_equal 101, shot.information.data["espresso_pressure"].size
      assert_equal 17, shot.information.extra.keys.size
      assert_equal "38.8", shot.drink_weight
      assert_equal "EK43 with SSP HU", shot.grinder_model
      assert_equal "2.1", shot.grinder_setting
      assert_equal "Banibeans", shot.bean_brand
      assert_equal "Ethiopia Shantawene", shot.bean_type
      assert_nil shot.roast_level
      assert_equal "11.09.2021", shot.roast_date
      assert_equal "0", shot.drink_tds
      assert_equal "0", shot.drink_ey
      assert_equal 70, shot.espresso_enjoyment
      assert_equal "Neat.", shot.espresso_notes
      assert_equal "With BPlus", shot.bean_notes
      assert_equal "Miha Rekar", shot.information.extra["my_name"]
      assert_equal "Miha Rekar", shot.barista
      assert_equal "MimojaCafe", shot.information.extra["skin"]
      assert_equal "1234", shot.information.extra["sn"]
      # FileUtils.cp(shot.information.tcl_profile, "#{path}.tcl")
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      # File.write("#{path}.json", shot.information.json_profile)
      assert_equal File.read("#{path}.json"), shot.information.json_profile
      # File.write("#{path}.csv", shot.information.csv_profile)
      assert_equal File.read("#{path}.csv"), shot.information.csv_profile
    end

    test "it creates a roaster and a coffee bag when user has coffee management enabled" do
      user = create(:user, :with_coffee_management)
      assert_equal 0, user.roasters.count
      assert_equal 0, user.coffee_bags.count

      shot = new_shot("test/files/20210921T085910.shot", user:)
      assert_equal user, shot.user
      assert_equal 1, user.roasters.count
      assert_equal 1, user.coffee_bags.count
      assert_equal "Banibeans", user.roasters.first.name
      assert_equal "Ethiopia Shantawene", user.coffee_bags.first.name
      assert_equal "", user.coffee_bags.first.roast_level
      assert_equal Date.new(2021, 9, 11), user.coffee_bags.first.roast_date
    end

    test "it overwrites existing shot if it exists" do
      user = create(:user)
      shot = new_shot("test/files/20210921T085910.shot", user:)
      shot.save!
      old_id = shot.id
      shot = new_shot("test/files/20210921T085910.shot", user:)
      shot.save!
      assert_equal old_id, shot.id
    end

    test "it resets coffee bag when user disables coffee management" do
      user = create(:user, :with_coffee_management)
      shot = new_shot("test/files/20210921T085910.shot", user:)
      shot.save!
      old_id = shot.id
      assert shot.coffee_bag_id
      user.update!(coffee_management_enabled: false)
      shot = new_shot("test/files/20210921T085910.shot", user:)
      shot.save!
      assert_equal old_id, shot.id
      assert_nil shot.coffee_bag_id
    end

    test "extracts the non-zero bean weight" do
      path = "test/files/dsx_weight"
      shot = new_shot("#{path}.shot")
      assert_in_delta(18.0, shot.bean_weight.to_f)
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      assert_equal File.read("#{path}.json"), shot.information.json_profile
    end

    test "handles invalid machine string" do
      path = "test/files/invalid_machine"
      shot = new_shot("#{path}.shot")
      assert_equal "Cremina lever machine", shot.profile_title
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      assert_equal File.read("#{path}.json"), shot.information.json_profile
    end

    test "handles brackets in advanced steps" do
      path = "test/files/brackets"
      shot = new_shot("#{path}.shot")
      assert_equal "Visualizer/manual 82", shot.profile_title
      assert_equal File.read("#{path}.tcl"), shot.information.tcl_profile
      assert_equal File.read("#{path}.json"), shot.information.json_profile
    end

    test "extracts roast date based on users date format" do
      user = create(:user, :with_coffee_management)
      shot = new_shot("test/files/20210921T085910.shot", user:)
      assert_equal "11.09.2021", shot.roast_date
      assert_equal Date.new(2021, 9, 11), shot.parsed_roast_date

      user.update!(date_format: "dd.mm.yyyy")
      shot = new_shot("test/files/20210921T085910.shot", user:)
      assert_equal "11.09.2021", shot.roast_date
      assert_equal Date.new(2021, 9, 11), shot.parsed_roast_date

      user.update!(date_format: "mm.dd.yyyy")
      shot = new_shot("test/files/20210921T085910.shot", user:)
      assert_equal "11.09.2021", shot.roast_date
      assert_equal Date.new(2021, 11, 9), shot.parsed_roast_date

      user.update!(date_format: "yyyy.mm.dd")
      shot = new_shot("test/files/20210921T085910ymd.shot", user:)
      assert_equal "2021.09.11", shot.roast_date
      assert_equal Date.new(2021, 9, 11), shot.parsed_roast_date
    end
  end
end
