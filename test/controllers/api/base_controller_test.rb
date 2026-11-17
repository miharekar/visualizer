require "test_helper"

module Api
  class BaseControllerTest < ActionDispatch::IntegrationTest
    test "rate limit is shared across API controllers" do
      50.times do
        get api_canonical_roasters_url, as: :json
        assert_response :success
      end

      get api_shots_url, as: :json

      assert_response :too_many_requests
      assert_equal "Too many requests. Please try again later.", response.parsed_body["error"]
    end

    test "basic auth skips bcrypt for repeat requests with the same credentials" do
      user = FactoryBot.create(:user)
      Rails.cache.clear

      calls = counting_bcrypt(user) do
        2.times do
          get api_me_url, headers: basic_headers(user.email, "password"), as: :json
          assert_response :success
        end
      end

      assert_equal 1, calls
    end

    test "basic auth authenticates non-ASCII passwords on first and cached requests" do
      user = FactoryBot.create(:user, password: "pässwörd")
      Rails.cache.clear

      calls = counting_bcrypt(user) do
        2.times do
          get api_me_url, headers: basic_headers(user.email, "pässwörd"), as: :json
          assert_response :success
        end
      end

      assert_equal 1, calls
    end

    test "basic auth rejects blank passwords without calling bcrypt" do
      user = FactoryBot.create(:user)
      Rails.cache.clear

      calls = counting_bcrypt(user) do
        get api_me_url, headers: basic_headers(user.email, ""), as: :json
        assert_response :unauthorized
      end

      assert_equal 0, calls
    end

    test "basic auth rejects and does not cache wrong passwords" do
      user = FactoryBot.create(:user)
      Rails.cache.clear

      2.times do
        get api_me_url, headers: basic_headers(user.email, "wrong"), as: :json
        assert_response :unauthorized
      end

      get api_me_url, headers: basic_headers(user.email, "password"), as: :json
      assert_response :success
    end

    test "cached basic auth stops working after a password change" do
      user = FactoryBot.create(:user)
      Rails.cache.clear

      get api_me_url, headers: basic_headers(user.email, "password"), as: :json
      assert_response :success

      user.update!(password: "new-password")

      get api_me_url, headers: basic_headers(user.email, "password"), as: :json
      assert_response :unauthorized

      get api_me_url, headers: basic_headers(user.email, "new-password"), as: :json
      assert_response :success
    end

    test "basic auth rejects unknown emails" do
      get api_me_url, headers: basic_headers("nobody@example.com", "password"), as: :json

      assert_response :unauthorized
    end

    test "basic auth normalizes whitespace and case in the email" do
      user = FactoryBot.create(:user)

      get api_me_url, headers: basic_headers("  #{user.email.upcase} ", "password"), as: :json

      assert_response :success
    end

    test "basic auth rejects empty and malformed credentials" do
      ["", "no-colon", ":", "#{FactoryBot.create(:user).email}:", ":password"].each do |credentials|
        get api_me_url, headers: {"HTTP_AUTHORIZATION" => "Basic #{Base64.strict_encode64(credentials)}"}, as: :json

        assert_response :unauthorized, "expected 401 for #{credentials.inspect}"
      end

      get api_me_url, headers: {"HTTP_AUTHORIZATION" => "Basic"}, as: :json

      assert_response :unauthorized
    end

    private

    def counting_bcrypt(user)
      calls = 0
      original = user.method(:authenticate_password)
      user.define_singleton_method(:authenticate_password) do |password|
        calls += 1
        original.call(password)
      end
      User.define_singleton_method(:find_by) { |*| user }
      yield
      calls
    ensure
      User.singleton_class.remove_method(:find_by)
    end

    def basic_headers(email, password)
      {"HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(email, password)}
    end
  end
end
