require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    host! "example.com"
    @user = create(:user, :premium)
    @shot = create(:shot, user: @user)
    sign_in(@user)
  end

  test "index directs JSON requests to the API documentation" do
    get shots_url(format: :json)

    assert_response :not_acceptable
    assert_equal "application/json", response.media_type
    assert_equal({
      "error" => "This is not an API endpoint.",
      "api_docs" => "https://apidocs.visualizer.coffee"
    }, response.parsed_body)
  end

  test "index renders Turbo Stream pagination" do
    get shots_url(format: :turbo_stream, before: 1.day.from_now.iso8601)

    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='append'][target='shots']"
  end

  test "show directs JSON requests to the API documentation" do
    get shot_url(@shot, format: :json)

    assert_response :not_acceptable
    assert_equal "application/json", response.media_type
    assert_equal({
      "error" => "This is not an API endpoint.",
      "api_docs" => "https://apidocs.visualizer.coffee"
    }, response.parsed_body)
  end

  test "show accepts wildcard format" do
    @shot.update!(duration: 30)

    get shot_url(@shot), headers: {"Accept" => "*/*"}

    assert_response :success
    assert_equal "text/html", response.media_type
  end

  test "rich notes use Lexxy and persist HTML" do
    @shot.update!(bean_notes: "<p><strong>Before</strong></p>")

    get edit_shot_url(@shot)

    assert_response :success
    assert_select "lexxy-editor[name='shot[bean_notes]']"
    assert_select "[data-controller='autocomplete'][data-action='autocomplete.change->canonical-selector#autocompleted']"
    assert_includes response.body, "&lt;strong&gt;Before&lt;/strong&gt;"

    patch shot_url(@shot), params: {shot: {
      bean_notes: "<p><strong>Chocolate</strong></p>",
      espresso_notes: "<p>Balanced</p>",
      private_notes: "<p>Grind finer</p>"
    }}

    assert_redirected_to shot_url(@shot)
    assert_equal "<p><strong>Chocolate</strong></p>", @shot.reload.rich_text_html(:bean_notes)
    assert_equal "<p>Balanced</p>", @shot.rich_text_html(:espresso_notes)
  end

  test "manual shots can be compared without charts" do
    comparison = create(:shot, user: @user, bean_weight: "18", duration: 30)
    get "/shots/#{@shot.id}/compare/#{comparison.id}"
    assert_response :success
    assert_select "#shot-chart", count: 0
    assert_select "#compare-range", count: 0
    assert_includes response.body, "Comparison"
  end

  test "new renders the shared manual form" do
    get "/shots/new"

    assert_response :success
    assert_select "form[action='#{shots_path}']"
    assert_select "input[name='shot[start_time]'][required]"
    assert_select "input[name='shot[duration]']"
    assert_select "lexxy-editor[name='shot[espresso_notes]']"
  end

  test "manual create uses server identity and user visibility" do
    @user.update!(public: true, name: "Barista", timezone: "Europe/Ljubljana")
    assert_difference "Shot.count" do
      post shots_url, params: {shot: {start_time: "2026-01-12T10:30:00", duration: "28.5", espresso_enjoyment: "85", profile_title: "Manual", tag_list: "morning", sha: "untrusted", user_id: SecureRandom.uuid, public: false}}
    end

    shot = @user.shots.order(:created_at).last
    assert_response :see_other
    assert_redirected_to shot_url(shot)
    assert shot.manual?
    assert shot.public?
    assert_match(/\Amanual:[0-9a-f-]{36}\z/, shot.sha)
    assert_equal Time.utc(2026, 1, 12, 9, 30), shot.start_time
    assert_equal 28.5, shot.duration
    assert_equal "morning", shot.tag_list
  end

  test "invalid manual create retains form values without persisting tags" do
    assert_no_difference ["Shot.count", "Tag.count", "ShotTag.count"] do
      post shots_url, params: {shot: {start_time: "", duration: "-1", espresso_enjoyment: "101", profile_title: "Keep me", tag_list: "unsaved"}}
    end

    assert_response :unprocessable_content
    assert_select ".text-red-600", text: /Start time/
    assert_select "input[name='shot[profile_title]'][value='Keep me']"
    assert_select "input[name='shot[tag_list]'][value='unsaved']"
  end

  test "manual form rejects nonfinite durations and invalid scores" do
    %w[NaN Infinity 1e999 nope].each do |duration|
      assert_no_difference "Shot.count" do
        post shots_url, params: {shot: {duration:}}
      end
      assert_response :unprocessable_content
    end
    ["-1", "101", "2.5", "NaN"].each do |score|
      assert_no_difference "Shot.count" do
        post shots_url, params: {shot: {espresso_enjoyment: score}}
      end
      assert_response :unprocessable_content
    end
  end

  test "failed edit renders dependencies and rolls back tag assignment" do
    @shot.update!(tag_list: "original")
    assert_no_difference ["Tag.count", "ShotTag.count"] do
      patch shot_url(@shot), params: {shot: {start_time: "", profile_title: "Retained", tag_list: "replacement"}}
    end

    assert_response :unprocessable_content
    assert_select "input[name='shot[profile_title]'][value='Retained']"
    assert_select "input[name='shot[tag_list]'][value='replacement']"
    assert_equal "original", @shot.reload.tag_list
    assert_not_equal "Retained", @shot.profile_title
  end

  test "manual edit accepts date and duration but imported edit protects them" do
    patch shot_url(@shot), params: {shot: {start_time: "2025-01-01T12:00:00Z", duration: "32"}}
    assert_response :see_other
    assert_equal Time.utc(2025, 1, 1, 12), @shot.reload.start_time
    assert_equal 32, @shot.duration

    imported = create(:shot, :with_information, user: @user, duration: 25)
    original_time = imported.start_time
    get edit_shot_url(imported)
    assert_response :success
    assert_select "input[name='shot[start_time]']", count: 0
    assert_select "input[name='shot[duration]']", count: 0
    patch shot_url(imported), params: {shot: {start_time: "2025-01-01T12:00:00Z", duration: "32", profile_title: "Allowed"}}
    assert_response :see_other
    assert_equal original_time, imported.reload.start_time
    assert_equal 25, imported.duration
    assert_equal "Allowed", imported.profile_title
  end

  test "manual create enforces daily limit by creation date" do
    @user.update!(premium_expires_at: nil)
    @shot.update!(start_time: 2.years.ago)
    create_list(:shot, Shot::DAILY_LIMIT - 1, user: @user, start_time: 2.years.ago)
    assert_no_difference "Shot.count" do
      post shots_url, params: {shot: {start_time: "2020-01-01T12:00:00Z"}}
    end
    assert_response :unprocessable_content
    assert_includes response.body, "daily limit"
  end

  test "form coffee bags are scoped to owner and include selected archived bag" do
    @user.update!(coffee_management_enabled: true)
    bag = create(:coffee_bag, roaster: create(:roaster, user: @user), archived_at: Time.current)
    @shot.update!(coffee_bag: bag)
    get edit_shot_url(@shot)
    assert_response :success
    assert_includes response.body, ERB::Util.html_escape(bag.full_display_name)

    foreign_bag = create(:coffee_bag)
    patch shot_url(@shot), params: {shot: {coffee_bag_id: foreign_bag.id}}
    assert_response :not_found
    assert_equal bag, @shot.reload.coffee_bag
  end

  test "file uploads still create imported shots and drag uploads return ok" do
    assert_difference "Shot.count" do
      post shots_url, params: {files: [fixture_file_upload(Rails.root.join("test/files/20210921T085910.shot"), "text/plain")]}
    end
    assert_redirected_to shots_url(format: :html)
    assert_not @user.shots.order(:created_at).last.manual?

    post shots_url, params: {files: [fixture_file_upload(Rails.root.join("test/files/20210921T085910.shot"), "text/plain")], drag: true}
    assert_response :ok
  end

  test "journal delete returns direct scoped streams and ordinary delete removes card" do
    delete shot_url(@shot), params: {journal: true, journal_search_id: "instance", query: {q: ""}}, as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action='remove'][target='journal-shot-#{@shot.id}']"
    assert_select "turbo-stream[action='update'][target='journal-count'] template", text: "No Shots"
    assert_select "turbo-stream[action='update'][target='journal-empty-instance'] template", text: "No matching shots."

    shot = create(:shot, user: @user)
    delete shot_url(shot), as: :turbo_stream
    assert_response :success
    assert_select "turbo-stream[action='remove'][target='shot_#{shot.id}']"
  end

  test "web JSON create and destroy direct clients to API without changing shots" do
    assert_no_difference "Shot.count" do
      post shots_url, params: {shot: {profile_title: "Manual"}}, as: :json
      assert_response :not_acceptable
      delete shot_url(@shot), as: :json
      assert_response :not_acceptable
    end
  end
end
