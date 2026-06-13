require "test_helper"

module Api
  class CanonicalCoffeeBagsControllerTest < ActionDispatch::IntegrationTest
    test "index searches canonical coffee bags without authentication" do
      roaster = CanonicalRoaster.create!(name: "Ritual")
      coffee_bag = CanonicalCoffeeBag.create!(name: "Ethiopia Aricha", canonical_roaster: roaster, country: "Ethiopia", variety: "Heirloom", tasting_notes: "Peach")
      CanonicalCoffeeBag.create!(name: "Kenya Gakuyuini", canonical_roaster: roaster)

      get api_canonical_coffee_bags_url, params: {q: "ethiopia"}, as: :json

      assert_response :success
      json_response = response.parsed_body
      assert_equal 1, json_response["data"].size
      assert_equal coffee_bag.id, json_response["data"].first["id"]
      assert_equal roaster.id, json_response["data"].first["canonical_roaster_id"]
      assert_equal "Ritual", json_response["data"].first["canonical_roaster_name"]
      assert_equal "Ethiopia", json_response["data"].first["country"]
      assert_equal "Heirloom", json_response["data"].first["variety"]
      assert_equal "Peach", json_response["data"].first["tasting_notes"]
      assert_equal 1, json_response["paging"]["count"]
    end

    test "index searches canonical coffee bags by canonical roaster name" do
      matching_roaster = CanonicalRoaster.create!(name: "Square Mile")
      matching_coffee_bag = CanonicalCoffeeBag.create!(name: "Kenya Gakuyuini", canonical_roaster: matching_roaster)
      other_roaster = CanonicalRoaster.create!(name: "Luna")
      CanonicalCoffeeBag.create!(name: "Kenya Kangocho", canonical_roaster: other_roaster)

      get api_canonical_coffee_bags_url, params: {q: "square"}, as: :json

      assert_response :success
      json_response = response.parsed_body
      assert_equal [matching_coffee_bag.id], json_response["data"].pluck("id")
    end

    test "index filters canonical coffee bags by canonical roaster id" do
      matching_roaster = CanonicalRoaster.create!(name: "Square Mile")
      matching_coffee_bag = CanonicalCoffeeBag.create!(name: "Kenya Gakuyuini", canonical_roaster: matching_roaster)
      other_roaster = CanonicalRoaster.create!(name: "Luna")
      CanonicalCoffeeBag.create!(name: "Kenya Kangocho", canonical_roaster: other_roaster)

      get api_canonical_coffee_bags_url, params: {q: "kenya", canonical_roaster_id: matching_roaster.id}, as: :json

      assert_response :success
      json_response = response.parsed_body
      assert_equal [matching_coffee_bag.id], json_response["data"].pluck("id")
    end
  end
end
