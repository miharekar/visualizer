require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
  end

  test "show paginates without exposing start times" do
    user = create(:user, :public, hide_shot_times: true)
    shots = 21.times.map { create(:shot, user:, public: true, start_time: (it + 1).minutes.ago) }

    get person_url(user.slug, format: :turbo_stream)

    assert_response :success
    frame = assert_select("turbo-stream[action='replace'][target='cursor'] turbo-frame#cursor[src]").first
    query = Rack::Utils.parse_query(URI.parse(frame["src"]).query)
    assert_equal shots[-2].id, query["before_id"]
    assert_no_match(/\d{4}-\d{2}-\d{2}/, query["before"])
    assert_equal shots[-2].start_time.to_i, Paginatable.decrypt_time(query["before"]).to_i

    get frame["src"], headers: {"Turbo-Frame" => "cursor"}

    assert_response :success
    assert_select "#shot_#{shots.last.id}"
  end

  test "show rejects a crafted before time" do
    user = create(:user, :public, hide_shot_times: true)
    create(:shot, user:, public: true, start_time: 1.hour.ago)

    get person_url(user.slug, format: :turbo_stream, before: 1.day.ago.iso8601)

    assert_response :bad_request
  end

  test "show redirects a public user's id to their slug" do
    user = create(:user, :public)

    get person_url(user.id)

    assert_redirected_to person_url(user.slug)
    assert_response :moved_permanently
  end

  test "show does not reveal the slug of a private user by id" do
    user = create(:user, :public)
    user.update!(public: false)

    get person_url(user.id)

    assert_redirected_to community_index_url
    assert_not_includes response.location, user.slug
  end

  test "feed redirects a public user's id to their slug" do
    user = create(:user, :public)

    get feed_person_url(user.id)

    assert_redirected_to feed_person_url(user.slug)
    assert_response :moved_permanently
  end

  test "feed does not reveal the slug of a private user by id" do
    user = create(:user, :public)
    user.update!(public: false)

    get feed_person_url(user.id)

    assert_response :not_found
  end
end
