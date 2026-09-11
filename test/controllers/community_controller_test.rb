require "test_helper"

class CommunityControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
  end

  test "index directs JSON requests to the API documentation" do
    get community_index_url(format: :json)

    assert_response :not_acceptable
    assert_equal "application/json", response.media_type
    assert_equal({
      "error" => "This is not an API endpoint.",
      "api_docs" => "https://apidocs.visualizer.coffee"
    }, response.parsed_body)
  end

  test "index renders HTML search with wildcard accept" do
    shot = create(:shot, public: true)

    get community_index_url(commit: "Search", user_id: shot.user_id), headers: {"Accept" => "*/*"}

    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "#shot_#{shot.id}"
  end

  test "index renders Turbo Stream pagination and retains filters" do
    user = create(:user)
    shots = 21.times.map { create(:shot, user:, public: true, start_time: (it + 1).minutes.ago) }
    other_shot = create(:shot, public: true)

    get community_index_url(format: :turbo_stream, commit: "Search", user_id: user.id, before: Time.current.iso8601), headers: {"Turbo-Frame" => "cursor"}

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='append'][target='shots']" do
      assert_select "#shot_#{shots.first.id}"
      assert_select "#shot_#{shots.last.id}", count: 0
      assert_select "#shot_#{other_shot.id}", count: 0
    end
    frames = assert_select "turbo-stream[action='replace'][target='cursor'] turbo-frame#cursor[src]"
    next_page = URI.parse(frames.first["src"])
    query = Rack::Utils.parse_query(next_page.query)
    assert_equal "/community", next_page.path
    assert_equal "turbo_stream", query["format"]
    assert_equal user.id, query["user_id"]
    assert_equal "Search", query["commit"]
    assert_equal shots.last.start_time.to_i, Time.iso8601(query["before"]).to_i

    get frames.first["src"], headers: {"Turbo-Frame" => "cursor"}

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='append'][target='shots'] #shot_#{shots.last.id}"
    assert_select "turbo-stream[action='replace'][target='cursor'] turbo-frame#cursor" do
      assert_select "[src]", count: 0
    end
  end
end
