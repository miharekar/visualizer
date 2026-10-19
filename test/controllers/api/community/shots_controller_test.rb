require "test_helper"

module Api
  module Community
    class ShotsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @owner = FactoryBot.create(:user)
        @premium = FactoryBot.create(:user, :premium)
      end

      test "index requires at least one filter" do
        get api_community_shots_url, as: :json
        assert_response :bad_request
        assert_equal "Provide at least one filter", response.parsed_body["error"]
      end

      test "index returns public shots matching the bean filters, times as unix seconds" do
        match = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia Aricha",
                              profile_title: "Blooming Espresso", espresso_enjoyment: 90)
        create(:shot, public: true, bean_brand: "Other Roaster", bean_type: "Brazil")

        get api_community_shots_url, params: {bean_brand: "ritual"}, as: :json

        assert_response :success
        data = response.parsed_body["data"]
        assert_equal [match.id], data.pluck("id")
        row = data.first
        assert_equal "Blooming Espresso", row["profile_title"]
        assert_equal 90, row["espresso_enjoyment"]
        assert_kind_of Integer, row["start_time"]
        assert_equal match.start_time.to_i, row["start_time"]
      end

      test "index excludes other users' private shots" do
        create(:shot, public: false, bean_brand: "Ritual", bean_type: "Ethiopia")

        get api_community_shots_url, params: {bean_brand: "ritual"}, as: :json

        assert_response :success
        assert_empty response.parsed_body["data"]
      end

      test "index includes your own private shots when authenticated" do
        mine = create(:shot, user: @owner, public: false, bean_brand: "Ritual", bean_type: "Ethiopia")

        get api_community_shots_url, params: {bean_brand: "ritual"}, headers: auth_headers(@owner), as: :json

        assert_response :success
        assert_equal [mine.id], response.parsed_body["data"].pluck("id")
      end

      test "index filters by canonical_coffee_bag_id" do
        roaster = CanonicalRoaster.create!(name: "Ritual")
        bag = CanonicalCoffeeBag.create!(name: "Ethiopia Aricha", canonical_roaster: roaster)
        match = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia", canonical_coffee_bag_id: bag.id)
        create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia")

        get api_community_shots_url, params: {canonical_coffee_bag_id: bag.id}, as: :json

        assert_response :success
        assert_equal [match.id], response.parsed_body["data"].pluck("id")
      end

      test "free viewers see only the last month while premium sees all history" do
        recent = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia")
        old = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia")
        old.update_column(:created_at, 2.months.ago)

        get api_community_shots_url, params: {bean_brand: "ritual"}, as: :json
        assert_response :success
        assert_equal [recent.id], response.parsed_body["data"].pluck("id")

        get api_community_shots_url, params: {bean_brand: "ritual"}, headers: auth_headers(@premium), as: :json
        assert_response :success
        assert_equal [old.id, recent.id].sort, response.parsed_body["data"].pluck("id").sort
      end

      test "shot times are hidden from other viewers when the owner opted out, user_name set for public users" do
        shy = FactoryBot.create(:user, :public, hide_shot_times: true)
        create(:shot, user: shy, public: true, bean_brand: "Ritual", bean_type: "Ethiopia")

        get api_community_shots_url, params: {bean_brand: "ritual"}, as: :json

        assert_response :success
        row = response.parsed_body["data"].first
        assert_not row.key?("start_time")
        assert_not row.key?("updated_at")
        assert_equal shy.display_name, row["user_name"]
      end

      test "index rejects a malformed uuid filter instead of dumping bagless shots" do
        create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia") # no canonical bag

        get api_community_shots_url, params: {canonical_coffee_bag_id: "not-a-uuid"}, as: :json

        assert_response :bad_request
        assert_equal "canonical_coffee_bag_id must be a valid UUID", response.parsed_body["error"]
      end

      test "index ignores unindexed note filters (bean_notes/espresso_notes)" do
        a = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia", bean_notes: "floral")
        b = create(:shot, public: true, bean_brand: "Ritual", bean_type: "Ethiopia", bean_notes: "chocolate")

        # If bean_notes were applied, only `a` would match; it must be ignored.
        get api_community_shots_url, params: {bean_brand: "ritual", bean_notes: "floral"}, as: :json

        assert_response :success
        assert_equal [a.id, b.id].sort, response.parsed_body["data"].pluck("id").sort
      end

      private

      def auth_headers(user)
        {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(user.email, "password")}
      end
    end
  end
end
