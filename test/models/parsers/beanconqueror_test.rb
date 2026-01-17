require "test_helper"

module Parsers
  class BeanconquerorTest < ActiveSupport::TestCase
    setup do
      @user = build_stubbed(:user)
    end

    def new_shot(path, user: @user)
      Shot.from_file(user, File.read(path))
    end

    test "extracts beanconqueror file" do
      shot = new_shot("test/files/beanconqueror.json")
      assert shot.valid?
      assert_equal "Chemex", shot.profile_title
      assert_equal "onoma", shot.bean_brand
      assert_equal "Holm", shot.bean_type
      assert_equal "75", shot.bean_weight
      assert_equal "AMERICAN_ROAST", shot.roast_level
      assert_equal "08.12.2022", shot.roast_date
      assert_equal "Kinu M47", shot.grinder_model
      assert_equal "4", shot.grinder_setting
      assert_equal "1200", shot.drink_weight
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
    end

    test "extracts real beanconqueror file" do
      shot = new_shot("test/files/beanconqueror_real.json")
      assert shot.valid?
      assert_equal "Chemex", shot.profile_title
      assert_equal "onoma", shot.bean_brand
      assert_equal "Holm", shot.bean_type
      assert_equal "75", shot.bean_weight
      assert_equal "AMERICAN_ROAST", shot.roast_level
      assert_equal "08.12.2022", shot.roast_date
      assert_equal "Kinu M47", shot.grinder_model
      assert_equal "4", shot.grinder_setting
      assert_equal "1200", shot.drink_weight
      assert_in_delta(35.047, shot.duration)
      assert_equal "3", shot.drink_tds
      assert_equal "4", shot.drink_ey
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
    end

    test "it creates a roaster and a coffee bag with details when user has coffee management enabled" do
      user = create(:user, :with_coffee_management)
      assert_equal 0, user.roasters.count
      assert_equal 0, user.coffee_bags.count

      shot = new_shot("test/files/beanconqueror_real.json", user:)
      assert_equal user, shot.user
      assert_equal 1, user.roasters.count
      assert_equal 1, user.coffee_bags.count
      assert_equal "onoma", user.roasters.first.name
      assert_equal "Holm", shot.coffee_bag.name
      assert_equal "AMERICAN_ROAST", shot.coffee_bag.roast_level
      assert_equal Date.new(2022, 12, 8), shot.coffee_bag.roast_date
      assert_equal "Country 1", shot.coffee_bag.country
      assert_equal "Region 1", shot.coffee_bag.region
      assert_equal "Farm 1", shot.coffee_bag.farm
      assert_equal "Farmer 1", shot.coffee_bag.farmer
      assert_equal "Variety 1", shot.coffee_bag.variety
      assert_equal "Elevation 1", shot.coffee_bag.elevation
      assert_equal "Processing 1", shot.coffee_bag.processing
      assert_equal "Harvest 1", shot.coffee_bag.harvest_time
      assert_equal "99", shot.coffee_bag.quality_score
      assert_equal "Schokolade, Haselnuss, Rund", shot.coffee_bag.tasting_notes
    end
    test "extracts real beanconqueror file with id to an existing shot and overwrites the information" do
      user = create(:user)
      shot = new_shot("test/files/beanconqueror_real.json", user:)
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save

      assert_equal "Chemex", shot.profile_title
      assert_equal "Kinu M47", shot.grinder_model
      assert_equal "4", shot.grinder_setting
      assert_equal "75", shot.bean_weight

      assert_equal "Kinu M47", shot.information.extra["grinder_model"]
      assert_equal "4", shot.information.extra["grinder_setting"]
      assert_equal 75, shot.information.extra["bean_weight"]

      assert_equal "Chemex", shot.information.brewdata["preparation"]["name"]
      assert_equal "Kinu M47", shot.information.brewdata["mill"]["name"]
      assert_equal "4", shot.information.brewdata["brew"]["grind_size"]
      assert_equal 75, shot.information.brewdata["brew"]["grind_weight"]

      updated = JSON.parse(File.read("test/files/beanconqueror_real_with_id.json"))
      updated["visualizerId"] = shot.id
      shot = Shot.from_file(user, JSON.generate(updated))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save

      shot = Shot.find(shot.id)

      assert_equal "V60", shot.profile_title
      assert_equal "Kinu 47", shot.grinder_model
      assert_equal "3.2", shot.grinder_setting
      assert_equal "78", shot.bean_weight

      assert_equal "Kinu 47", shot.information.extra["grinder_model"]
      assert_equal "3.2", shot.information.extra["grinder_setting"]
      assert_equal 78, shot.information.extra["bean_weight"]

      assert_equal "V60", shot.information.brewdata["preparation"]["name"]
      assert_equal "Kinu 47", shot.information.brewdata["mill"]["name"]
      assert_equal "3.2", shot.information.brewdata["brew"]["grind_size"]
      assert_equal 78, shot.information.brewdata["brew"]["grind_weight"]
    end

    test "extracts real beanconqueror file with id to a new shot when existing belongs to a different user" do
      create(:shot, id: "00000244-0bad-4ddd-ac8f-fe7b29e10313", user: create(:user))
      shot = new_shot("test/files/beanconqueror_real_with_id.json", user: create(:user))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_not_equal "00000244-0bad-4ddd-ac8f-fe7b29e10313", shot.id
    end

    test "extracts real beanconqueror file with id to a new shot when existing shot doesn't exist" do
      shot = new_shot("test/files/beanconqueror_real_with_id.json", user: create(:user))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_not_equal "00000244-0bad-4ddd-ac8f-fe7b29e10313", shot.id
    end

    test "extracts real beanconqueror file with standard id to an existing shot and overwrites the information" do
      user = create(:user)
      create(:shot, id: "2a8479ed-6487-446e-b16b-de1c137e0cc0", user:, bean_brand: "test")
      shot = new_shot("test/files/beanconqueror_real_with_id_standard.json", user:)
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_equal "2a8479ed-6487-446e-b16b-de1c137e0cc0", shot.id
      assert_equal "onoma new", shot.bean_brand
    end

    test "extracts real beanconqueror file with standard id to a new shot when existing belongs to a different user" do
      create(:shot, id: "2a8479ed-6487-446e-b16b-de1c137e0cc0", user: create(:user))
      shot = new_shot("test/files/beanconqueror_real_with_id_standard.json", user: create(:user))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_not_equal "2a8479ed-6487-446e-b16b-de1c137e0cc0", shot.id
    end

    test "extracts real beanconqueror file with standard id to a new shot when existing shot doesn't exist" do
      shot = new_shot("test/files/beanconqueror_real_with_id_standard.json", user: create(:user))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_not_equal "2a8479ed-6487-446e-b16b-de1c137e0cc0", shot.id
    end

    test "extracts real beanconqueror file to a new shot when no id" do
      shot = new_shot("test/files/beanconqueror_real.json", user: create(:user))
      assert shot.valid?
      assert_equal "Parsers::Beanconqueror", shot.information.brewdata["parser"]
      shot.save
      assert_not_equal "00000244-0bad-4ddd-ac8f-fe7b29e10313", shot.id
    end

    test "extracts long beanconqueror file with negative values" do
      shot = new_shot("test/files/beanconqueror_negative.json")
      assert shot.valid?
      assert_equal "Chemex", shot.profile_title
      assert_equal "onoma", shot.bean_brand
      assert_equal "Holm", shot.bean_type
      assert_equal "75", shot.bean_weight
      assert_equal "AMERICAN_ROAST", shot.roast_level
      assert_equal "08.12.2022", shot.roast_date
      assert_equal "Kinu M47", shot.grinder_model
      assert_equal "4", shot.grinder_setting
      assert_equal "1200", shot.drink_weight
      assert_in_delta(174.244, shot.duration)
      assert_equal %w[pressureFlow realtimeFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 1748, shot.information.brewdata["brewFlow"]["realtimeFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end

    test "extracts long beanconqueror file with missing values" do
      shot = new_shot("test/files/beanconqueror_missing_values.json")
      assert shot.valid?
      assert_equal "Hario V60", shot.profile_title
      assert_equal "Leaderboard 03", shot.bean_type
      assert_equal "15", shot.bean_weight
      assert_in_delta(147.542, shot.duration)
      assert_equal %w[pressureFlow realtimeFlow temperatureFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 1366, shot.information.brewdata["brewFlow"]["realtimeFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end

    test "extracts correct weight from beanconqueror file" do
      shot = new_shot("test/files/beanconqueror_beverage_weight.json")
      assert shot.valid?
      assert_equal "Ice V60", shot.profile_title
      assert_equal "Brasil Jabuticaba", shot.bean_type
      assert_equal "16.2", shot.bean_weight
      assert_equal "249", shot.drink_weight
      assert_in_delta(163.198, shot.duration)
      assert_equal %w[pressureFlow realtimeFlow temperatureFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 1117, shot.information.brewdata["brewFlow"]["realtimeFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end

    test "extracts temperature from Beanconqueror" do
      shot = new_shot("test/files/beanconqueror_temperature.json")
      assert shot.valid?
      assert_in_delta(17.201, shot.duration)
      assert_equal %w[pressureFlow realtimeFlow temperatureFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 16, shot.information.brewdata["brewFlow"]["temperatureFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end

    test "extracts basket temperature from Beanconqueror" do
      shot = new_shot("test/files/beanconqueror_temperature_extended.json")
      assert shot.valid?
      assert_in_delta(17.201, shot.duration)
      assert_equal %w[basketTemperatureFlow pressureFlow realtimeFlow targetTemperatureFlow temperatureFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 15, shot.information.brewdata["brewFlow"]["basketTemperatureFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end

    test "extracts target temperature from Beanconqueror" do
      shot = new_shot("test/files/beanconqueror_temperature_extended.json")
      assert shot.valid?
      assert_in_delta(17.201, shot.duration)
      assert_equal %w[basketTemperatureFlow pressureFlow realtimeFlow targetTemperatureFlow temperatureFlow waterFlow weight], shot.information.brewdata["brewFlow"].keys.sort
      assert_equal 14, shot.information.brewdata["brewFlow"]["targetTemperatureFlow"].size
      assert_equal 10, shot.information.extra.keys.size
    end
  end
end
