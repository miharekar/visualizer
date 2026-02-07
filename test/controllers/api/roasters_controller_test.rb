require "test_helper"

module Api
  class RoastersControllerTest < ActionDispatch::IntegrationTest
    attr_reader :user, :premium_user

    setup do
      @user = FactoryBot.create(:user)
      @premium_user = FactoryBot.create(:user, :premium)
    end

    test "create creates roaster for premium user" do
      post api_roasters_url, headers: auth_headers(premium_user), params: {roaster: {name: "Luma", website: "https://luma.example"}}, as: :json

      assert_response :created
      json_response = response.parsed_body
      assert_equal "Luma", json_response["name"]
      assert_equal premium_user.id, Roaster.find(json_response["id"]).user_id
    end

    test "create requires premium user" do
      post api_roasters_url, headers: auth_headers(user), params: {roaster: {name: "Luma"}}, as: :json

      assert_response :forbidden
      assert_equal "You must be a premium user to access this feature.", response.parsed_body["error"]
    end

    test "update updates owned roaster" do
      roaster = FactoryBot.create(:roaster, user: premium_user, name: "Before")

      patch api_roaster_url(roaster), headers: auth_headers(premium_user), params: {roaster: {name: "After"}}, as: :json

      assert_response :success
      assert_equal "After", roaster.reload.name
    end

    test "update returns not found for unowned roaster" do
      roaster = FactoryBot.create(:roaster)

      patch api_roaster_url(roaster), headers: auth_headers(premium_user), params: {roaster: {name: "After"}}, as: :json

      assert_response :not_found
      assert_equal "Roaster not found", response.parsed_body["error"]
    end

    test "destroy deletes owned roaster" do
      roaster = FactoryBot.create(:roaster, user: premium_user)

      delete api_roaster_url(roaster), headers: auth_headers(premium_user), as: :json

      assert_response :success
      assert_not Roaster.exists?(roaster.id)
      assert_equal true, response.parsed_body["success"]
    end

    private

    def auth_headers(user)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
    end
  end
end
