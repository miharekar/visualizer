require "test_helper"

module Api
  class CoffeeBagsControllerTest < ActionDispatch::IntegrationTest
    attr_reader :user, :premium_user

    setup do
      host! "example.com"
      @user = FactoryBot.create(:user)
      @premium_user = FactoryBot.create(:user, :premium)
    end

    test "create creates coffee bag for premium user" do
      roaster = FactoryBot.create(:roaster, user: premium_user)

      post api_coffee_bags_url, headers: auth_headers(premium_user), params: {coffee_bag: {name: "Kiambu", roast_date: "2025-01-01", roaster_id: roaster.id}}, as: :json

      assert_response :created
      json_response = response.parsed_body
      assert_equal "Kiambu", json_response["name"]
      assert_equal roaster.id, CoffeeBag.find(json_response["id"]).roaster_id
    end

    test "create requires premium user" do
      roaster = FactoryBot.create(:roaster, user:)

      post api_coffee_bags_url, headers: auth_headers(user), params: {coffee_bag: {name: "Kiambu", roaster_id: roaster.id}}, as: :json

      assert_response :forbidden
      assert_equal "You must be a premium user to access this feature.", response.parsed_body["error"]
    end

    test "update updates coffee bag and allows moving to another owned roaster" do
      roaster = FactoryBot.create(:roaster, user: premium_user)
      other_roaster = FactoryBot.create(:roaster, user: premium_user, name: "Other")
      coffee_bag = FactoryBot.create(:coffee_bag, roaster:, name: "Before")

      patch api_coffee_bag_url(coffee_bag), headers: auth_headers(premium_user), params: {coffee_bag: {name: "After", roaster_id: other_roaster.id}}, as: :json

      assert_response :success
      coffee_bag.reload
      assert_equal "After", coffee_bag.name
      assert_equal other_roaster.id, coffee_bag.roaster_id
    end

    test "update returns not found for unowned coffee bag" do
      coffee_bag = FactoryBot.create(:coffee_bag)

      patch api_coffee_bag_url(coffee_bag), headers: auth_headers(premium_user), params: {coffee_bag: {name: "After"}}, as: :json

      assert_response :not_found
      assert_equal "Coffee bag not found", response.parsed_body["error"]
    end

    test "destroy deletes coffee bag" do
      coffee_bag = FactoryBot.create(:coffee_bag, roaster: FactoryBot.create(:roaster, user: premium_user))

      delete api_coffee_bag_url(coffee_bag), headers: auth_headers(premium_user), as: :json

      assert_response :success
      assert_not CoffeeBag.exists?(coffee_bag.id)
      assert_equal true, response.parsed_body["success"]
    end

    test "legacy nested index endpoint redirects to root coffee bags endpoint" do
      roaster = FactoryBot.create(:roaster, user: premium_user)

      get "/api/roasters/#{roaster.id}/coffee_bags?items=5&page=2", headers: auth_headers(premium_user)

      assert_response :moved_permanently
      assert_redirected_to "/api/coffee_bags?items=5&page=2&roaster_id=#{roaster.id}"
    end

    test "legacy nested show endpoint redirects to root coffee bag endpoint" do
      coffee_bag = FactoryBot.create(:coffee_bag, roaster: FactoryBot.create(:roaster, user: premium_user))

      get "/api/roasters/#{coffee_bag.roaster_id}/coffee_bags/#{coffee_bag.id}", headers: auth_headers(premium_user)

      assert_response :moved_permanently
      assert_redirected_to "/api/coffee_bags/#{coffee_bag.id}"
    end

    private

    def auth_headers(user)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
    end
  end
end
