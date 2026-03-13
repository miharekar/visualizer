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
      shot = FactoryBot.create(:shot, user:, private_notes: "Only for me")

      get api_shot_url(shot), headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
      expected_keys = %w[
        barista bean_brand bean_notes bean_type bean_weight brewdata drink_ey drink_tds drink_weight duration
        espresso_enjoyment espresso_notes grinder_model grinder_setting id private_notes profile_title roast_date
        roast_level start_time tags updated_at user_id
      ]
      assert_equal expected_keys.sort, json_response.keys.sort
      assert_equal shot.updated_at.to_i, json_response["updated_at"]
      assert_equal "Only for me", json_response["private_notes"]
    end

    test "show returns tasting assessment data when present" do
      shot = FactoryBot.create(
        :shot,
        user:,
        fragrance: 1,
        aroma: 2,
        flavor: 3,
        aftertaste: 4,
        acidity: 5,
        bitterness: 6,
        sweetness: 7,
        mouthfeel: 8
      )

      get api_shot_url(shot), headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal 1, json_response["fragrance"]
      assert_equal 2, json_response["aroma"]
      assert_equal 3, json_response["flavor"]
      assert_equal 4, json_response["aftertaste"]
      assert_equal 5, json_response["acidity"]
      assert_equal 6, json_response["bitterness"]
      assert_equal 7, json_response["sweetness"]
      assert_equal 8, json_response["mouthfeel"]
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
      shot = FactoryBot.create(:shot, user:, private_notes: "Only for me")

      get api_shot_url(shot), params: {format: "unknown"}, headers: auth_headers(user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_equal shot.id, json_response["id"]
      expected_keys = %w[
        barista bean_brand bean_notes bean_type bean_weight brewdata drink_ey drink_tds drink_weight duration
        espresso_enjoyment espresso_notes grinder_model grinder_setting id private_notes profile_title roast_date
        roast_level start_time tags updated_at user_id
      ]
      assert_equal expected_keys.sort, json_response.keys.sort
      assert_equal shot.updated_at.to_i, json_response["updated_at"]
      assert_equal "Only for me", json_response["private_notes"]
    end

    test "show does not expose private notes to other users" do
      shot = FactoryBot.create(:shot, user:, private_notes: "Only for me")

      get api_shot_url(shot), headers: auth_headers(public_user), as: :json
      assert_response :success

      json_response = response.parsed_body
      assert_not_includes json_response.keys, "private_notes"
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

      assert_response :unprocessable_content
      json_response = response.parsed_body
      assert_equal "No shot file provided. Provide a file parameter with a multipart/form-data request or a JSON body with a valid JSON object.", json_response["error"]
    end

    test "upload returns error when file content is invalid" do
      post upload_api_shots_url, headers: auth_headers(user), params: "{ invalid json content", as: :json

      assert_response :unprocessable_content
      json_response = response.parsed_body
      assert json_response["error"].present?
      assert_includes json_response["error"], "Could not save the provided file"
    end

    test "update returns updated shot for JSON request" do
      shot = FactoryBot.create(:shot, user:, profile_title: "Old title")

      patch api_shot_url(shot), headers: auth_headers(user), params: {shot: {profile_title: "New title"}}, as: :json

      assert_response :success
      assert_match "application/json", response.media_type

      json_response = response.parsed_body
      assert_equal "New title", json_response["profile_title"]
    end

    test "update rejects non-json request" do
      shot = FactoryBot.create(:shot, user:)

      patch api_shot_url(shot), headers: auth_headers(user).merge("CONTENT_TYPE" => "application/x-www-form-urlencoded"), params: {shot: {profile_title: "New title"}}

      assert_response :unprocessable_content
      json_response = response.parsed_body
      assert_equal "Request must be JSON.", json_response["error"]
    end

    test "update allows shot metadata fields for premium users" do
      premium_user = FactoryBot.create(:user, :premium, :with_shot_metadata)
      shot = FactoryBot.create(:shot, user: premium_user)

      patch api_shot_url(shot), headers: auth_headers(premium_user), params: {shot: {metadata: {"Portafilter basket" => "IMS"}}}, as: :json

      assert_response :success
      assert_equal({"Portafilter basket" => "IMS"}, shot.reload.metadata)
    end

    test "update allows tasting assessment fields for premium users" do
      premium_user = FactoryBot.create(:user, :premium)
      shot = FactoryBot.create(:shot, user: premium_user)

      patch api_shot_url(shot), headers: auth_headers(premium_user), params: {shot: {fragrance: 10, aroma: 9, flavor: 12, aftertaste: 11, acidity: 7, bitterness: 6, sweetness: 8, mouthfeel: 13}}, as: :json

      assert_response :success
      shot.reload
      assert_equal 10, shot.fragrance
      assert_equal 9, shot.aroma
      assert_equal 12, shot.flavor
      assert_equal 11, shot.aftertaste
      assert_equal 7, shot.acidity
      assert_equal 6, shot.bitterness
      assert_equal 8, shot.sweetness
      assert_equal 13, shot.mouthfeel
    end

    test "update rejects shot metadata fields for non-premium users" do
      shot = FactoryBot.create(:shot, user:)

      patch api_shot_url(shot), headers: auth_headers(user), params: {shot: {metadata: {"Portafilter basket" => "IMS"}}}, as: :json

      assert_response :bad_request
      assert_empty shot.reload.metadata
    end

    test "update rejects tasting assessment fields for non-premium users" do
      shot = FactoryBot.create(:shot, user:)

      patch api_shot_url(shot), headers: auth_headers(user), params: {shot: {fragrance: 10}}, as: :json

      assert_response :bad_request
      assert_nil shot.reload.fragrance
    end

    test "basic auth does not create a persisted session or set a session cookie" do
      FactoryBot.create(:shot, user:, public: true)

      assert_no_difference "Session.count" do
        get api_shots_url, headers: auth_headers(user), as: :json
      end

      assert_response :success
      assert_not_includes response.headers["Set-Cookie"].to_s, "session_id="
    end

    test "bearer auth does not create a persisted session or set a session cookie" do
      token = create_access_token_for(user)
      FactoryBot.create(:shot, user:, public: true)

      assert_no_difference "Session.count" do
        get api_shots_url, headers: bearer_headers(token), as: :json
      end

      assert_response :success
      assert_not_includes response.headers["Set-Cookie"].to_s, "session_id="
    end

    test "cookie-backed api auth still works with a persisted session" do
      FactoryBot.create(:shot, user:, public: true)

      assert_difference "Session.count", 1 do
        post session_url, params: {email: user.email, password: "password"}
      end

      assert_redirected_to shots_url

      assert_no_difference "Session.count" do
        get api_shots_url, as: :json
      end

      assert_response :success
      assert_equal 1, response.parsed_body.dig("paging", "count")
    end

    private

    def auth_headers(user)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
    end

    def bearer_headers(token)
      {"Authorization" => "Bearer #{token.token}"}
    end

    def create_access_token_for(user)
      application = Doorkeeper::Application.create!(name: "Test App", owner: user, redirect_uri: "urn:ietf:wg:oauth:2.0:oob")
      Doorkeeper::AccessToken.create!(application:, resource_owner_id: user.id, scopes: "read write upload", expires_in: 1.week)
    end
  end
end
