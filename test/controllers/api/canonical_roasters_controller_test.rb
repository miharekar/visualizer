require "test_helper"

module Api
  class CanonicalRoastersControllerTest < ActionDispatch::IntegrationTest
    test "index searches canonical roasters without authentication" do
      matching_roaster = CanonicalRoaster.create!(name: "Square Mile", website: "https://squaremilecoffee.com", country: "United Kingdom")
      CanonicalRoaster.create!(name: "Luna")

      get api_canonical_roasters_url, params: {q: "square"}, as: :json

      assert_response :success
      json_response = response.parsed_body
      assert_equal 1, json_response["data"].size
      assert_equal matching_roaster.id, json_response["data"].first["id"]
      assert_equal "Square Mile", json_response["data"].first["name"]
      assert_equal "https://squaremilecoffee.com", json_response["data"].first["website"]
      assert_equal "United Kingdom", json_response["data"].first["country"]
      assert_equal 1, json_response["paging"]["count"]
    end
  end
end
