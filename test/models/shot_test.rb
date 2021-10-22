# frozen_string_literal: true

require "test_helper"

class ShotTest < ActiveSupport::TestCase
  test "extracts fields from .shot file" do
    path = "test/fixtures/files/20210921T085910"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal users(:miha), shot.user
    assert_equal "JoeD's Easy blooming slow ramp to 7 bar", shot.profile_title
    assert_equal "2021-09-21 06:59:10", shot.start_time.to_s(:db)
    assert_equal 100, shot.timeframe.size
    assert_equal "0.044", shot.timeframe.first
    assert_equal "24.793", shot.timeframe.last
    assert_equal Shot::DATA_LABELS.sort, shot.data.keys.sort
    assert_equal 101, shot.data["espresso_pressure"].size
    assert_equal 14, shot.extra.keys.size
    assert_equal "38.8", shot.drink_weight
    assert_equal "EK43 with SSP HU", shot.grinder_model
    assert_equal "2.1", shot.grinder_setting
    assert_equal "Bani Beans", shot.bean_brand
    assert_equal "Ethiopia Shantawene", shot.bean_type
    assert_nil shot.roast_level
    assert_equal "11.09.2021", shot.roast_date
    assert_equal "0", shot.drink_tds
    assert_equal "0", shot.drink_ey
    assert_equal 70, shot.espresso_enjoyment
    assert_equal "Neat.", shot.espresso_notes
    assert_equal "With BPlus", shot.bean_notes
    # FileUtils.cp(shot.tcl_profile, "#{path}.tcl")
    assert_equal File.read("#{path}.tcl"), File.read(shot.tcl_profile)
    # File.write("#{path}.json", shot.json_profile)
    assert_equal File.read("#{path}.json"), shot.json_profile
  end

  test "extracts fields from .json upload file and replaces content when .shot of same shot" do
    path = "test/fixtures/files/20211019T100744"
    shot = Shot.from_file(users(:miha), "#{path}.json")
    assert_equal users(:miha), shot.user
    assert_equal "Easy blooming - active pressure decline", shot.profile_title
    assert_equal "2021-10-19 08:07:44", shot.start_time.to_s(:db)
    assert_equal 109, shot.timeframe.size
    assert_equal "0.044", shot.timeframe.first
    assert_equal "26.999", shot.timeframe.last
    assert_equal Shot::DATA_LABELS.sort, shot.data.keys.sort
    assert_equal 110, shot.data["espresso_pressure"].size
    assert_equal 16, shot.extra.keys.size
    assert_equal 46, shot.profile_fields.keys.size
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
    assert_equal File.read("#{path}.tcl"), File.read(shot.tcl_profile)
    assert_equal File.read("#{path}.json_profile"), shot.json_profile

    shot.save!
    old_id = shot.id
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    shot.save!
    assert_equal old_id, shot.id

    assert_equal users(:miha), shot.user
    assert_equal "Easy blooming - active pressure decline", shot.profile_title
    assert_equal "2021-10-19 08:07:44", shot.start_time.to_s(:db)
    assert_equal 109, shot.timeframe.size
    assert_equal "0.044", shot.timeframe.first
    assert_equal "26.999", shot.timeframe.last
    assert_equal Shot::DATA_LABELS.sort, shot.data.keys.sort
    assert_equal 110, shot.data["espresso_pressure"].size
    assert_equal 14, shot.extra.keys.size
    assert_equal 46, shot.profile_fields.keys.size
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
    assert_equal File.read("#{path}.tcl"), File.read(shot.tcl_profile)
    assert_equal File.read("#{path}.json_profile"), shot.json_profile
  end

  test "extracts the non-zero bean weight" do
    path = "test/fixtures/files/dsx_weight"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal 18.0, shot.bean_weight.to_f
    assert_equal File.read("#{path}.tcl"), File.read(shot.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.json_profile
  end

  test "handles invalid machine string" do
    path = "test/fixtures/files/invalid_machine"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal "Cremina lever machine", shot.profile_title
    assert_equal File.read("#{path}.tcl"), File.read(shot.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.json_profile
  end
end
