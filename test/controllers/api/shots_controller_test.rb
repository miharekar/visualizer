require "test_helper"

module Api
  class ShotsControllerTest < ActionDispatch::IntegrationTest
    attr_reader :user, :public_user, :premium_user

    setup do
      @user = FactoryBot.create(:user)
      @public_user = FactoryBot.create(:user, :public)
      @premium_user = FactoryBot.create(:user, :premium)
    end

    test "index returns correct data for authenticated user" do
      FactoryBot.create_list(:shot, 5, user:, public: true)

      get api_shots_url, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 5, json_response["data"].length
      assert_includes json_response, "paging"
      assert_equal %w[count page limit pages], json_response["paging"].keys
      assert_equal 5, json_response["paging"]["count"]
      assert_equal 1, json_response["paging"]["page"]
      assert_equal 10, json_response["paging"]["limit"]
      assert_equal 1, json_response["paging"]["pages"]

      shot_data = json_response["data"].first
      assert_equal %w[clock id], shot_data.keys

      get api_shots_url(items: 2, page: 3), headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 1, json_response["data"].length

      assert_equal 5, json_response["paging"]["count"]
      assert_equal 3, json_response["paging"]["page"]
      assert_equal 2, json_response["paging"]["limit"]
      assert_equal 3, json_response["paging"]["pages"]

      shot_data = json_response["data"].first
      assert_equal %w[clock id], shot_data.keys
    end

    test "index respects limit parameter" do
      FactoryBot.create_list(:shot, 5, user:, public: true)

      get api_shots_url, params: {items: 3}, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 3, json_response["data"].length
    end

    test "index caps limit at 100" do
      # start_time is way in the past to get around the daily limit
      FactoryBot.create_list(:shot, 101, user:, public: true, start_time: 2.days.ago)

      get api_shots_url, params: {items: 150}, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 100, json_response["data"].length
    end

    test "index returns only public shots for unauthenticated user" do
      FactoryBot.create(:shot, user:)
      FactoryBot.create(:shot, user: public_user)

      get api_shots_url, as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 1, json_response["data"].length
    end

    test "index returns non-premium shots for non-premium user" do
      FactoryBot.create_list(:shot, 5, user:, public: true)
      FactoryBot.create(:shot, user: premium_user, public: true)

      get api_shots_url, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 5, json_response["data"].length
    end

    test "shared returns all shared shots for authenticated user" do
      shot_1 = create(:shot, user:)
      shot_2 = create(:shot, user: public_user)
      create(:shared_shot, shot: shot_1, user:)
      create(:shared_shot, shot: shot_2, user:)

      get shared_api_shots_url, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 2, json_response.length

      shot_ids = json_response.pluck("id")
      assert_includes shot_ids, shot_1.id
      assert_includes shot_ids, shot_2.id
    end

    test "shared returns specific shot for authenticated user with valid code" do
      create(:shared_shot, user:)

      shot = create(:shot, user: public_user)
      create(:shared_shot, shot:, code: "TEST")

      get shared_api_shots_url(code: "TEST"), headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
    end

    test "shared returns shot for unauthenticated user with valid code" do
      shot = create(:shot, user:)
      create(:shared_shot, shot:, code: "TEST")

      get shared_api_shots_url(code: "TEST"), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
    end

    test "shared returns not found for unauthenticated user with invalid code" do
      get shared_api_shots_url(code: "INVALID"), as: :json
      assert_response :not_found

      json_response = response.parsed_body
      assert_equal "Shared shot not found", json_response["error"]
    end

    private

    def auth_headers(user)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
    end
  end
end
