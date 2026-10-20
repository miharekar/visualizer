require "test_helper"

class CoffeeManagementUpdateJobTest < ActiveJob::TestCase
  test "relinking shots to coffee bags restores their canonical coffee" do
    user = create(:user, :with_coffee_management)
    roaster = create(:roaster, user:, name: "Square Mile")
    canonical_bag = CanonicalCoffeeBag.create!(name: "Ethiopia Aricha", canonical_roaster: CanonicalRoaster.create!(name: "Square Mile"))
    coffee_bag = create(:coffee_bag, roaster:, name: "Ethiopia Aricha", roast_date: nil, canonical_coffee_bag: canonical_bag)
    shot = create(:shot, user:, bean_brand: "Square Mile", bean_type: "Ethiopia Aricha", roast_date: nil)

    CoffeeManagementUpdateJob.perform_now(user)

    assert_equal coffee_bag.id, shot.reload.coffee_bag_id
    assert_equal canonical_bag.id, shot.canonical_coffee_bag_id
  end
end
