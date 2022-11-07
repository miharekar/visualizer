# frozen_string_literal: true

require "test_helper"

class ShotTest < ActiveSupport::TestCase
  test "extracts fields from .shot file" do
    path = "test/fixtures/files/20210921T085910"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal users(:miha), shot.user
    assert_equal "JoeD's Easy blooming slow ramp to 7 bar", shot.profile_title
    assert_equal "2021-09-21 06:59:10", shot.start_time.to_fs(:db)
    assert_equal 100, shot.information.timeframe.size
    assert_equal "0.044", shot.information.timeframe.first
    assert_equal "24.793", shot.information.timeframe.last
    assert_equal 24.793, shot.duration
    assert_equal Shot::DATA_LABELS.sort, shot.information.data.keys.sort
    assert_equal 101, shot.information.data["espresso_pressure"].size
    assert_equal 16, shot.information.extra.keys.size
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
    assert_equal "Miha Rekar", shot.information.extra["my_name"]
    assert_equal "Miha Rekar", shot.barista
    assert_equal "MimojaCafe", shot.information.extra["skin"]
    # FileUtils.cp(shot.information.tcl_profile, "#{path}.tcl")
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    # File.write("#{path}.json", shot.information.json_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "extracts fields from .json upload file and replaces content when .shot of same shot" do
    path = "test/fixtures/files/20211019T100744"
    shot = Shot.from_file(users(:miha), "#{path}.json")
    assert_equal users(:miha), shot.user
    assert_equal "Easy blooming - active pressure decline", shot.profile_title
    assert_equal "2021-10-19 08:07:44", shot.start_time.to_fs(:db)
    assert_equal 109, shot.information.timeframe.size
    assert_equal "0.044", shot.information.timeframe.first
    assert_equal "26.999", shot.information.timeframe.last
    assert_equal 26.999, shot.duration
    assert_equal Shot::DATA_LABELS.sort, shot.information.data.keys.sort
    assert_equal 110, shot.information.data["espresso_pressure"].size
    assert_equal 18, shot.information.extra.keys.size
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
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json_profile"), shot.information.json_profile

    shot.save!
    old_id = shot.id
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    shot.save!
    assert_equal old_id, shot.id

    assert_equal users(:miha), shot.user
    assert_equal "Easy blooming - active pressure decline", shot.profile_title
    assert_equal "2021-10-19 08:07:44", shot.start_time.to_fs(:db)
    assert_equal 109, shot.information.timeframe.size
    assert_equal "0.044", shot.information.timeframe.first
    assert_equal "26.999", shot.information.timeframe.last
    assert_equal 26.999, shot.duration
    assert_equal Shot::DATA_LABELS.sort, shot.information.data.keys.sort
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
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json_profile"), shot.information.json_profile
  end

  test "extracts the non-zero bean weight" do
    path = "test/fixtures/files/dsx_weight"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal 18.0, shot.bean_weight.to_f
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles invalid machine string" do
    path = "test/fixtures/files/invalid_machine"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal "Cremina lever machine", shot.profile_title
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles brackets in advanced steps" do
    path = "test/fixtures/files/brackets"
    shot = Shot.from_file(users(:miha), "#{path}.shot")
    assert_equal "manual 82", shot.profile_title
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles invalid profile string" do
    path = "test/fixtures/files/invalid_profile"
    shot = Shot.from_file(users(:miha), "#{path}.json")
    assert_not shot.valid?
  end

  test "smart espresso profiler file" do
    path = "test/fixtures/files/sharebrew_tsp.csv"
    shot = Shot.from_file(users(:miha), path)
    assert_equal 450, shot.information.timeframe.size
    assert_equal "0.051", shot.information.timeframe.first
    assert_equal "48.403", shot.information.timeframe.last
    assert_equal 48.403, shot.duration
    assert_equal 9, shot.information.extra.keys.size
    assert_equal "TSP18 Z", shot.profile_title
    assert_equal "Espresso Machine Brand: Flair PRO\nBrew ratio: 1.0\nExtraction time: 48.403\nAvarage flow rate: 0.6406627688366423\nUnit system: metric\nAttribution: Smart Espresso Profiler\nSoftware: Smart Espresso Profiler App\nUrl: https://itunes.apple.com/hu/app/smart-espresso-profiler/id1391707089\nExport version: 1.1.0", shot.espresso_notes
    assert_equal "Herd", shot.bean_brand
    assert_equal "Kenya", shot.bean_type
    assert_equal "Medium", shot.roast_level
    assert_equal "2021-12-17", shot.roast_date
    assert_equal "Comandante Trailmaster", shot.grinder_model
    assert_equal "3 clicks", shot.grinder_setting
    assert_equal "15.2", shot.bean_weight
    assert_equal "31.01", shot.drink_weight
  end
end
