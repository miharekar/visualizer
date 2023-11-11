# frozen_string_literal: true

require "test_helper"

class ShotTest < ActiveSupport::TestCase
  def new_shot(path)
    Shot.from_file(users(:miha), File.read(path))
  end

  test "returns invalid Shot with empty file" do
    shot = Shot.from_file(users(:miha), "")
    assert_not shot.valid?
  end

  test "extracts fields from .shot file" do
    path = "test/fixtures/files/20210921T085910"
    shot = new_shot("#{path}.shot")
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
    shot = new_shot("#{path}.json")
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
    shot = new_shot("#{path}.shot")
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
    shot = new_shot("#{path}.shot")
    assert_equal 18.0, shot.bean_weight.to_f
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles invalid machine string" do
    path = "test/fixtures/files/invalid_machine"
    shot = new_shot("#{path}.shot")
    assert_equal "Cremina lever machine", shot.profile_title
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles brackets in advanced steps" do
    path = "test/fixtures/files/brackets"
    shot = new_shot("#{path}.shot")
    assert_equal "manual 82", shot.profile_title
    assert_equal File.read("#{path}.tcl"), File.read(shot.information.tcl_profile)
    assert_equal File.read("#{path}.json"), shot.information.json_profile
  end

  test "handles invalid profile string" do
    shot = new_shot("test/fixtures/files/invalid_profile.json")
    assert shot.valid?
    assert_equal "phaad/Extractamundo Dos!", shot.profile_title
    assert_equal 101, shot.information.timeframe.size
  end

  test "handles even more invalid profile string" do
    shot = new_shot("test/fixtures/files/invalid_profile_2.json")
    assert shot.valid?
    assert_equal "fill brew release", shot.profile_title
    assert_equal 237, shot.information.timeframe.size
  end

  test "handles invalid settings" do
    shot = new_shot("test/fixtures/files/invalid_settings.json")
    assert shot.valid?
    assert_equal "HELLCAFE Synesso mvp", shot.profile_title
    assert_equal 145, shot.information.timeframe.size
  end

  test "handles very invalid settings" do
    shot = new_shot("test/fixtures/files/very_invalid_settings.json")
    assert shot.valid?
    assert_equal "Visualizer/Filter 2.0.2 15 in 18 1:4-5", shot.profile_title
    assert_equal 679, shot.information.timeframe.size
  end

  test "smart espresso profiler file" do
    shot = new_shot("test/fixtures/files/sharebrew_tsp.csv")
    assert_equal 451, shot.information.timeframe.size
    assert_equal 0.051, shot.information.timeframe.first
    assert_equal 48.403, shot.information.timeframe.last
    assert_equal 48.403, shot.duration
    assert_equal 9, shot.information.extra.keys.size
    assert_equal %w[espresso_flow_weight espresso_weight], shot.information.data.keys.sort
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

  test "handles invalid file" do
    shot = new_shot("test/fixtures/files/invalid_file.something")
    assert_not shot.valid?
  end

  test "handles pyde1 fake tcl file" do
    shot = new_shot("test/fixtures/files/pyde.faketcl")
    assert shot.valid?
    assert_equal "Extractamundo Dos!", shot.profile_title
    assert_equal 98, shot.information.timeframe.size
  end

  test "handles empty instructions inside advanced_shot" do
    shot = new_shot("test/fixtures/files/empty_flow.shot")
    assert shot.valid?
    assert_equal "6BarFlat", shot.profile_title
    assert_equal 80, shot.information.timeframe.size
  end

  test "extracts beanconqueror file" do
    shot = new_shot("test/fixtures/files/beanconqueror.json")
    assert shot.valid?
    assert_equal "onoma", shot.bean_brand
    assert_equal "Holm", shot.bean_type
    assert_equal "75", shot.bean_weight
    assert_equal "AMERICAN_ROAST", shot.roast_level
    assert_equal "2022-12-08T06:24:32.574Z", shot.roast_date
    assert shot.bean_notes.start_with?("```javascript")
    assert shot.bean_notes.include?('"aromatics": "Schokolade, Haselnuss, Rund"')
    assert_equal "Kinu M47", shot.grinder_model
    assert_equal "4", shot.grinder_setting
    assert_equal "0", shot.drink_weight
    assert shot.espresso_notes.include?("#### Brew")
    assert shot.espresso_notes.include?("\n\n```javascript")
    assert shot.espresso_notes.include?('"brew_beverage_quantity_type": "GR"')
    assert_not shot.espresso_notes.include?("config")
    assert shot.espresso_notes.include?("#### Preparation")
    assert shot.espresso_notes.include?('"type": "CHEMEX"')
    assert shot.espresso_notes.include?("#### Water")
    assert shot.espresso_notes.include?('"tds_type": "PPM"')
  end

  test "extracts real beanconqueror file" do
    shot = new_shot("test/fixtures/files/beanconqueror_real.json")
    assert shot.valid?
    assert_equal "onoma", shot.bean_brand
    assert_equal "Holm", shot.bean_type
    assert_equal "75", shot.bean_weight
    assert_equal "AMERICAN_ROAST", shot.roast_level
    assert_equal "2022-12-08T06:24:32.574Z", shot.roast_date
    assert shot.bean_notes.start_with?("```javascript")
    assert shot.bean_notes.include?('"aromatics": "Schokolade, Haselnuss, Rund"')
    assert_equal "Kinu M47", shot.grinder_model
    assert_equal "4", shot.grinder_setting
    assert_equal "0", shot.drink_weight
    assert shot.espresso_notes.include?("#### Brew")
    assert shot.espresso_notes.include?("\n\n```javascript")
    assert shot.espresso_notes.include?('"brew_beverage_quantity_type": "GR"')
    assert_not shot.espresso_notes.include?("config")
    assert shot.espresso_notes.include?("#### Preparation")
    assert shot.espresso_notes.include?('"type": "CHEMEX"')
    assert shot.espresso_notes.include?("#### Water")
    assert shot.espresso_notes.include?('"tds_type": "PPM"')
    assert_equal 488, shot.information.timeframe.size
    assert_equal "0.0", shot.information.timeframe.first
    assert_equal "34.858", shot.information.timeframe.last
    assert_equal 34.858, shot.duration
    assert_equal %w[espresso_flow espresso_flow_weight espresso_pressure espresso_weight], shot.information.data.keys.sort
    assert_equal 488, shot.information.data["espresso_weight"].size
    assert_equal 10, shot.information.extra.keys.size
  end

  test "extracts long beanconqueror file with negative values" do
    shot = new_shot("test/fixtures/files/beanconqueror_negative.json")
    assert shot.valid?
    assert_equal "onoma", shot.bean_brand
    assert_equal "Holm", shot.bean_type
    assert_equal "75", shot.bean_weight
    assert_equal "AMERICAN_ROAST", shot.roast_level
    assert_equal "2022-12-08T06:24:32.574Z", shot.roast_date
    assert shot.bean_notes.start_with?("```javascript")
    assert shot.bean_notes.include?('"aromatics": "Schokolade, Haselnuss, Rund"')
    assert_equal "Kinu M47", shot.grinder_model
    assert_equal "4", shot.grinder_setting
    assert_equal "0", shot.drink_weight
    assert shot.espresso_notes.include?("#### Brew")
    assert shot.espresso_notes.include?("\n\n```javascript")
    assert shot.espresso_notes.include?('"brew_beverage_quantity_type": "GR"')
    assert_not shot.espresso_notes.include?("config")
    assert shot.espresso_notes.include?("#### Preparation")
    assert shot.espresso_notes.include?('"type": "CHEMEX"')
    assert shot.espresso_notes.include?("#### Water")
    assert shot.espresso_notes.include?('"tds_type": "PPM"')
    assert_equal 1748, shot.information.timeframe.size
    assert_equal "0.0", shot.information.timeframe.first
    assert_equal "174.243", shot.information.timeframe.last
    assert_equal 174.243, shot.duration
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], shot.information.data.keys.sort
    assert_equal 1748, shot.information.data["espresso_weight"].size
    assert_equal 10, shot.information.extra.keys.size
    assert shot.information.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "extracts long beanconqueror file with missing values" do
    shot = new_shot("test/fixtures/files/beanconqueror_missing_values.json")
    assert shot.valid?
    assert_equal "Leaderboard 03", shot.bean_type
    assert_equal "15", shot.bean_weight
    assert shot.espresso_notes.include?("#### Water")
    assert shot.espresso_notes.include?('"name": "Aquacode (85ppm)",')
    assert_equal 1366, shot.information.timeframe.size
    assert_equal "0.0", shot.information.timeframe.first
    assert_equal "147.542", shot.information.timeframe.last
    assert_equal 147.542, shot.duration
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], shot.information.data.keys.sort
    assert_equal 1366, shot.information.data["espresso_weight"].size
    assert_equal 10, shot.information.extra.keys.size
    assert shot.information.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "extracts correct weight from beanconqueror file" do
    shot = new_shot("test/fixtures/files/beanconqueror_beverage_weight.json")
    assert shot.valid?
    assert_equal "Brasil Jabuticaba", shot.bean_type
    assert_equal "16.2", shot.bean_weight
    assert_equal "249", shot.drink_weight
    assert_equal 1117, shot.information.timeframe.size
    assert_equal "0.0", shot.information.timeframe.first
    assert_equal "163.197", shot.information.timeframe.last
    assert_equal 163.197, shot.duration
    assert_equal %w[espresso_flow espresso_flow_weight espresso_weight], shot.information.data.keys.sort
    assert_equal 1117, shot.information.data["espresso_weight"].size
    assert_equal 10, shot.information.extra.keys.size
    assert shot.information.data["espresso_flow_weight"].all? { |v| v >= 0 }
  end

  test "extracts pressure from CoffeeFlow app" do
    shot = new_shot("test/fixtures/files/profitec_victoria_arduino.csv")
    assert shot.valid?
    assert_equal 1074, shot.information.timeframe.size
    assert_equal 0.336, shot.information.timeframe.first
    assert_equal 58.536, shot.information.timeframe.last
    assert_equal 58.536, shot.duration
    assert_equal %w[espresso_flow_weight espresso_pressure espresso_weight], shot.information.data.keys.sort
    assert_equal 4.660000000000004, shot.information.data["espresso_weight"][400]
    assert_equal 8.727121090778084, shot.information.data["espresso_pressure"][400]
    assert_equal 0.73, shot.information.data["espresso_flow_weight"][400]
    assert_equal 9, shot.information.extra.keys.size
    assert_equal "Profitec/Victoria Arduino dual spring setup", shot.profile_title
    assert_equal "Espresso Machine Brand: Profitec\nEspresso Machine Model: Pro800\nBrew ratio: 1.0\nExtraction time: 58.536\nAvarage flow rate: 0.6551523848571821\nUnit system: metric\nAttribution: Coffee Flow\nSoftware: Coffee Flow\nUrl: https://itunes.apple.com/hu/app/smart-espresso-profiler/id1391707089\nExport version: 1.1.0", shot.espresso_notes
    assert_equal "Kavekalmar", shot.bean_brand
    assert_equal "Brasil Cerrado Mineiro", shot.bean_type
    assert_equal "dark", shot.roast_level
    assert_equal "2020-11-18", shot.roast_date
    assert_equal "Eureka Atom Specialty", shot.grinder_model
    assert_equal "18.6", shot.bean_weight
    assert_equal "38.35", shot.drink_weight
  end

  test "extracts temperature from Pressensor" do
    shot = new_shot("test/fixtures/files/pressensor.csv")
    assert shot.valid?
    assert_equal 703, shot.information.timeframe.size
    assert_equal 0.033, shot.information.timeframe.first
    assert_equal 33.082, shot.information.timeframe.last
    assert_equal 33.082, shot.duration
    assert_equal %w[espresso_flow_weight espresso_pressure espresso_temperature_mix espresso_weight], shot.information.data.keys.sort
    assert_equal 27.29, shot.information.data["espresso_weight"][400]
    assert_equal 1.488175344887875, shot.information.data["espresso_pressure"][400]
    assert_equal 0.66, shot.information.data["espresso_flow_weight"][400]
    assert_equal 6, shot.information.extra.keys.size
    assert_equal "My espresso #438", shot.profile_title
    assert_equal "Basket Diameter: 58.8\nBasket Capacity: 15.8\nBrew ratio: 1.0\nExtraction time: 33.085\nAvarage flow rate: 1.1446274746864138\nUnit system: metric\nAttribution: Coffee Flow\nSoftware: Coffee Flow\nUrl: https://itunes.apple.com/hu/app/smart-espresso-profiler/id1391707089\nExport version: 1.1.0", shot.espresso_notes
    assert_equal "Kávékalmár", shot.bean_brand
    assert_equal "Ethiopia Banti Nenka", shot.bean_type
    assert_equal "Medium", shot.roast_level
    assert_equal "16.2", shot.bean_weight
    assert_equal "37.87", shot.drink_weight
  end

  test "extracts correct length from Pressensor" do
    shot = new_shot("test/fixtures/files/pressensor_short.csv")
    assert shot.valid?
    assert_equal 182, shot.information.timeframe.size
    assert_equal 0.028, shot.information.timeframe.first
    assert_equal 18.638, shot.information.timeframe.last.round(3)
    assert_equal 18.638, shot.duration.round(3)
    assert_equal %w[espresso_flow_weight espresso_pressure espresso_temperature_mix espresso_weight], shot.information.data.keys.sort
    assert_equal 36.06, shot.information.data["espresso_weight"][150]
    assert_equal 1.771564746242297, shot.information.data["espresso_pressure"][150]
    assert_equal 0.04, shot.information.data["espresso_flow_weight"][150]
    assert_equal 10, shot.information.extra.keys.size
    assert_equal "First Pull", shot.profile_title
    assert_equal "Espresso Machine Brand: Flair 58\nEspresso Machine Model: f58\nBasket Diameter: 58.0\nBrew ratio: 1.0\nExtraction time: 18.674\nAvarage flow rate: 1.931562600406983\nUnit system: metric\nAttribution: Pressensor CF\nSoftware: Pressensor CF\nUrl: https://itunes.apple.com/hu/app/smart-espresso-profiler/id1391707089\nExport version: 1.1.0", shot.espresso_notes
    assert_equal "Ninetens", shot.bean_brand
    assert_equal "Kintamani Cascara Washed", shot.bean_type
    assert_equal "Medium", shot.roast_level
    assert_equal "16.0", shot.bean_weight
    assert_equal "36.07", shot.drink_weight
  end

  test "extracts temperature from Beanconqueror" do
    shot = new_shot("test/fixtures/files/beanconqueror_temperature.json")
    assert shot.valid?
    assert_equal 16, shot.information.timeframe.size
    assert_equal "0.0", shot.information.timeframe.first
    assert_equal "17.148", shot.information.timeframe.last
    assert_equal 17.148, shot.duration
    assert_equal %w[espresso_flow espresso_flow_weight espresso_temperature_mix espresso_weight], shot.information.data.keys.sort
    assert_equal 16, shot.information.data["espresso_weight"].size
    assert_equal 10, shot.information.extra.keys.size
  end
end
