require "test_helper"

class CoffeeBagTest < ActiveSupport::TestCase
  attr_reader :user, :roaster

  setup do
    @user = FactoryBot.create(:user, :with_coffee_management)
    @roaster = FactoryBot.create(:roaster, user:)
  end

  test ".for_roaster_by_name_and_date creates a new CoffeeBag if one does not exist" do
    shot = FactoryBot.build_stubbed(:shot, user:, bean_type: "Ethiopian", roast_date: "2023-10-01", roast_level: "Medium")

    assert_difference "CoffeeBag.count", 1 do
      CoffeeBag.for_roaster_by_name_and_date(roaster, shot.bean_type, shot.roast_date, roast_level: shot.roast_level)
    end

    coffee_bag = CoffeeBag.last
    assert_equal "Ethiopian", coffee_bag.name
    assert_equal Date.parse("2023-10-01"), coffee_bag.roast_date
    assert_equal "Medium", coffee_bag.roast_level
    assert_equal roaster.id, coffee_bag.roaster_id
  end

  test ".for_roaster_by_name_and_date finds an existing CoffeeBag if one exists" do
    roast_date = "2023-10-01".to_date
    coffee_bag = roaster.coffee_bags.create(name: "Ethiopian", roast_date:, roast_level: "Medium")

    shot = FactoryBot.build_stubbed(:shot, user:, bean_type: "Ethiopian", roast_date: "2023-10-01", roast_level: "Medium")

    assert_no_difference "CoffeeBag.count" do
      found_bag = CoffeeBag.for_roaster_by_name_and_date(roaster, shot.bean_type, shot.roast_date, roast_level: shot.roast_level)
      assert_equal coffee_bag, found_bag
    end
  end

  test ".for_roaster_by_name_and_date finds an existing CoffeeBag if one exists case insensitive" do
    roast_date = "2023-10-01".to_date
    coffee_bag = roaster.coffee_bags.create(name: "Ethiopian", roast_date:, roast_level: "Medium")

    shot = FactoryBot.build_stubbed(:shot, user:, bean_type: "eThIoPiAN", roast_date: "2023-10-01", roast_level: "Medium")

    assert_no_difference "CoffeeBag.count" do
      found_bag = CoffeeBag.for_roaster_by_name_and_date(roaster, shot.bean_type, shot.roast_date, roast_level: shot.roast_level)
      assert_equal coffee_bag, found_bag
    end
  end

  test ".for_roaster_by_name_and_date handles invalid roast_date in shot" do
    shot = FactoryBot.build_stubbed(:shot, user:, bean_type: "Ethiopian", roast_date: "invalid-date", roast_level: "Medium")

    assert_difference "CoffeeBag.count", 1 do
      CoffeeBag.for_roaster_by_name_and_date(roaster, shot.bean_type, shot.roast_date, roast_level: shot.roast_level)
    end

    coffee_bag = CoffeeBag.last
    assert_equal "Ethiopian", coffee_bag.name
    assert_nil coffee_bag.roast_date
    assert_equal "Medium", coffee_bag.roast_level
    assert_equal roaster.id, coffee_bag.roaster_id
  end
end
