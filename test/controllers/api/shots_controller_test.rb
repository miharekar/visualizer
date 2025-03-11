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
      assert_equal %w[clock id updated_at], shot_data.keys

      get api_shots_url(items: 2, page: 3), headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 1, json_response["data"].length

      assert_equal 5, json_response["paging"]["count"]
      assert_equal 3, json_response["paging"]["page"]
      assert_equal 2, json_response["paging"]["limit"]
      assert_equal 3, json_response["paging"]["pages"]

      shot_data = json_response["data"].first
      assert_equal %w[clock id updated_at], shot_data.keys
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

    test "show returns shot data" do
      shot = FactoryBot.create(:shot, user:)

      get api_shot_url(shot), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
      expected_keys = %w[
        barista bean_brand bean_notes bean_type bean_weight brewdata drink_ey drink_tds drink_weight duration
        espresso_enjoyment espresso_notes grinder_model grinder_setting id profile_title roast_date roast_level
        start_time tags updated_at user_id
      ]
      assert_equal expected_keys.sort, json_response.keys.sort
      assert_equal shot.updated_at.to_i, json_response["updated_at"]
    end

    test "show returns shot data in beanconqueror format" do
      shot = FactoryBot.create(:shot, user:)

      get api_shot_url(shot), params: {format: "beanconqueror"}, as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response.dig("meta", "visualizer", "shot_id")
      expected_keys = %w[bean brew meta mill preparation]
      assert_equal expected_keys.sort, json_response.keys.sort
      assert_equal shot.updated_at.to_i, json_response.dig("meta", "visualizer", "updated_at")
    end

    test "show returns shot data in decent format for unknown format" do
      shot = FactoryBot.create(:shot, user:)

      get api_shot_url(shot), params: {format: "unknown"}, as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
      expected_keys = %w[
        barista bean_brand bean_notes bean_type bean_weight brewdata drink_ey drink_tds drink_weight duration
        espresso_enjoyment espresso_notes grinder_model grinder_setting id profile_title roast_date roast_level
        start_time tags updated_at user_id
      ]
      assert_equal expected_keys.sort, json_response.keys.sort
      assert_equal shot.updated_at.to_i, json_response["updated_at"]
    end

    test "show returns 404 for non-existent shot" do
      get api_shot_url(id: "nonexistent"), as: :json
      assert_response :not_found

      json_response = response.parsed_body
      assert_equal "Shot not found", json_response["error"]
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

    test "upload accepts multipart/form-data with file parameter" do
      file_content = Rails.root.join("test/files/beanconqueror.json").read
      file = Tempfile.new(["sample_shot.json"])
      file.write(file_content)
      file.rewind

      post upload_api_shots_url, headers: auth_headers(user), params: {file: fixture_file_upload(file.path, "application/json")}

      assert_response :success
      json_response = response.parsed_body
      assert json_response["id"].present?

      # Verify the shot was created
      shot = Shot.find(json_response["id"])
      assert_equal user.id, shot.user_id
    end

    test "upload accepts JSON POST with raw body" do
      file_content = JSON.parse(Rails.root.join("test/files/beanconqueror.json").read)

      post upload_api_shots_url, headers: auth_headers(user), params: file_content, as: :json

      assert_response :success
      json_response = response.parsed_body
      assert json_response["id"].present?

      # Verify the shot was created
      shot = Shot.find(json_response["id"])
      assert_equal user.id, shot.user_id
    end

    test "upload returns error when no file content is provided" do
      post upload_api_shots_url, headers: auth_headers(user)

      assert_response :unprocessable_entity
      json_response = response.parsed_body
      assert_equal "No shot file provided. Provide a file parameter with a multipart/form-data request or a JSON body with a valid JSON object.", json_response["error"]
    end

    test "upload returns error when file content is invalid" do
      post upload_api_shots_url, headers: auth_headers(user), params: "{ invalid json content", as: :json

      assert_response :unprocessable_entity
      json_response = response.parsed_body
      assert json_response["error"].present?
      assert_includes json_response["error"], "Could not save the provided file"
    end

    private

    def auth_headers(user)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
    end
  end
end
