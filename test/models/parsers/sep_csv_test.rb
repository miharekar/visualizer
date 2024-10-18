require "test_helper"

class Parsers::SepCsvTest < ActiveSupport::TestCase
  setup do
    @user = build_stubbed(:user)
  end

  def new_shot(path, user: @user)
    Shot.from_file(user, File.read(path))
  end
  test "smart espresso profiler file" do
    shot = new_shot("test/files/sharebrew_tsp.csv")
    assert_equal "Parsers::SepCsv", shot.information.brewdata["parser"]
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
    assert_equal "17.12.2021", shot.roast_date
    assert_equal "Comandante Trailmaster", shot.grinder_model
    assert_equal "3 clicks", shot.grinder_setting
    assert_equal "15.2", shot.bean_weight
    assert_equal "31.01", shot.drink_weight
  end

  test "extracts pressure from CoffeeFlow app" do
    shot = new_shot("test/files/profitec_victoria_arduino.csv")
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
    assert_equal "18.11.2020", shot.roast_date
    assert_equal "Eureka Atom Specialty", shot.grinder_model
    assert_equal "18.6", shot.bean_weight
    assert_equal "38.35", shot.drink_weight
    assert_equal "Parsers::SepCsv", shot.information.brewdata["parser"]
    assert_equal File.read("test/files/profitec_victoria_arduino_profile.csv"), shot.information.csv_profile
  end

  test "extracts temperature from Pressensor" do
    shot = new_shot("test/files/pressensor.csv")
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
    assert_equal "Parsers::SepCsv", shot.information.brewdata["parser"]
    assert_equal File.read("test/files/pressensor_profile.csv"), shot.information.csv_profile
  end

  test "extracts correct length from Pressensor" do
    shot = new_shot("test/files/pressensor_short.csv")
    assert shot.valid?
    assert_equal 182, shot.information.timeframe.size
    assert_equal 0.028, shot.information.timeframe.first
    assert_equal 18.638, shot.information.timeframe.last.round(3)
    assert_equal 18.638, shot.duration.round(3)
    assert_equal %w[espresso_flow_weight espresso_pressure espresso_temperature_mix espresso_weight], shot.information.data.keys.sort
    assert_equal 36.06, shot.information.data["espresso_weight"][150]
    assert_equal 1.771564746242297, shot.information.data["espresso_pressure"][150]
    assert_equal 1.45, shot.information.data["espresso_flow_weight"][50]
    assert_equal 0.04, shot.information.data["espresso_flow_weight"][150]
    assert_equal 10, shot.information.extra.keys.size
    assert_equal "First Pull", shot.profile_title
    assert_equal "Espresso Machine Brand: Flair 58\nEspresso Machine Model: f58\nBasket Diameter: 58.0\nBrew ratio: 1.0\nExtraction time: 18.674\nAvarage flow rate: 1.931562600406983\nUnit system: metric\nAttribution: Pressensor CF\nSoftware: Pressensor CF\nUrl: https://itunes.apple.com/hu/app/smart-espresso-profiler/id1391707089\nExport version: 1.1.0", shot.espresso_notes
    assert_equal "Ninetens", shot.bean_brand
    assert_equal "Kintamani Cascara Washed", shot.bean_type
    assert_equal "Medium", shot.roast_level
    assert_equal "16.0", shot.bean_weight
    assert_equal "36.07", shot.drink_weight
    assert_equal "Parsers::SepCsv", shot.information.brewdata["parser"]
    assert_equal File.read("test/files/pressensor_short_profile.csv"), shot.information.csv_profile
  end
end
