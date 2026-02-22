require "test_helper"

class CanonicalControllerTest < ActionDispatch::IntegrationTest
  test "autocomplete_coffee_bags returns results without canonical roaster filter" do
    roaster = CanonicalRoaster.create!(name: "Ritual")
    coffee_bag = CanonicalCoffeeBag.create!(name: "Ethiopia Aricha", canonical_roaster: roaster)

    get autocomplete_coffee_bags_canonical_index_url, params: {q: "ethiopia"}

    assert_response :success
    assert_includes response.body, coffee_bag.name
  end

  test "autocomplete_coffee_bags returns no results when roaster is required but missing" do
    roaster = CanonicalRoaster.create!(name: "Ritual")
    coffee_bag = CanonicalCoffeeBag.create!(name: "Ethiopia Aricha", canonical_roaster: roaster)

    get autocomplete_coffee_bags_canonical_index_url, params: {q: "ethiopia", require_roaster: true}

    assert_response :success
    assert_not_includes response.body, coffee_bag.name
  end

  test "autocomplete_coffee_bags filters by canonical roaster id when provided" do
    matching_roaster = CanonicalRoaster.create!(name: "Square Mile")
    matching_coffee_bag = CanonicalCoffeeBag.create!(name: "Kenya Gakuyuini", canonical_roaster: matching_roaster)
    other_roaster = CanonicalRoaster.create!(name: "Luna")
    CanonicalCoffeeBag.create!(name: "Kenya Kangocho", canonical_roaster: other_roaster)

    get autocomplete_coffee_bags_canonical_index_url, params: {q: "kenya", canonical_roaster_id: matching_roaster.id, require_roaster: true}

    assert_response :success
    assert_includes response.body, matching_coffee_bag.name
    assert_not_includes response.body, "Kenya Kangocho"
  end
end
