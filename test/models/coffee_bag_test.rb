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

  test "frozen? is true only when frozen date exists and defrosted date is blank" do
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: Date.new(2025, 1, 10), defrosted_date: nil)
    assert coffee_bag.frozen?

    coffee_bag.update!(defrosted_date: Date.new(2025, 1, 15))
    assert_not coffee_bag.frozen?
  end

  test "days_in_freezer returns nil when never frozen" do
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: nil, defrosted_date: nil)

    assert_nil coffee_bag.days_in_freezer(up_to: Date.new(2025, 1, 9))
  end

  test "days_in_freezer returns nil when shot date is before frozen date" do
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: Date.new(2025, 1, 10), defrosted_date: nil)

    assert_nil coffee_bag.days_in_freezer(up_to: Date.new(2025, 1, 9))
  end

  test "days_in_freezer uses shot date when bag is still frozen" do
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: Date.new(2025, 1, 10), defrosted_date: nil)

    assert_equal 5, coffee_bag.days_in_freezer(up_to: Date.new(2025, 1, 15))
  end

  test "days_in_freezer uses defrosted date when it is before shot date" do
    coffee_bag = create(:coffee_bag, roaster:, frozen_date: Date.new(2025, 1, 10), defrosted_date: Date.new(2025, 1, 12))

    assert_equal 2, coffee_bag.days_in_freezer(up_to: Date.new(2025, 1, 15))
  end

  test "defrosted date must be after frozen date" do
    coffee_bag = build(:coffee_bag, roaster:, roast_date: Date.new(2025, 1, 1), frozen_date: Date.new(2025, 1, 10), defrosted_date: Date.new(2025, 1, 9))

    assert_not coffee_bag.valid?
    assert_includes coffee_bag.errors[:defrosted_date], "must be after frozen date"
  end

  test "defrosted date requires frozen date" do
    coffee_bag = build(:coffee_bag, roaster:, roast_date: Date.new(2025, 1, 1), frozen_date: nil, defrosted_date: Date.new(2025, 1, 9))

    assert_not coffee_bag.valid?
    assert_includes coffee_bag.errors[:defrosted_date], "requires a frozen date"
  end

  test "active_first orders active, then frozen, then archived" do
    active = create(:coffee_bag, roaster:, name: "Active", roast_date: Date.new(2024, 1, 1), frozen_date: nil, defrosted_date: nil, archived_at: nil)
    frozen = create(:coffee_bag, roaster:, name: "Frozen", roast_date: Date.new(2024, 2, 1), frozen_date: Date.new(2024, 2, 5), defrosted_date: nil, archived_at: nil)
    archived = create(:coffee_bag, roaster:, name: "Archived", roast_date: Date.new(2024, 3, 1), frozen_date: nil, defrosted_date: nil, archived_at: Time.current)

    assert_equal [active.id, frozen.id, archived.id], CoffeeBag.where(id: [active.id, frozen.id, archived.id]).active_first.pluck(:id)
  end

  test "metadata defaults to empty hash" do
    coffee_bag = create(:coffee_bag, roaster:, metadata: nil)

    assert_equal({}, coffee_bag.metadata)
    assert_nil coffee_bag.to_api_json["metadata"]
  end

  test "to_api_json includes metadata" do
    coffee_bag = create(:coffee_bag, roaster:, metadata: {"Bean density" => "High"})

    assert_equal({"Bean density" => "High"}, coffee_bag.to_api_json["metadata"])
  end
end
