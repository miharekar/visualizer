require "test_helper"

class JournalsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    host! "visualizer.test"
    https!
    @user = create(:user, :premium, timezone: "Ljubljana", journal_enabled: true)
    @shot = create(:shot, :with_information, user: @user, duration: 28, bean_weight: "18", espresso_notes: "<p><strong>Sweet</strong></p>")
    sign_in(@user)
  end

  test "journal replaces shots index without beta and renders editors" do
    get shots_url
    assert_response :success
    assert_select "tr[data-shot-id='#{@shot.id}']"
    assert_select "td[data-column='start_time'] a[href='#{shot_path(@shot)}']"
    assert_select "td[data-column='bean_weight'] input[data-editor]"
    assert_select "td[data-column='bean_weight'] [data-display]", count: 0
    assert_select "lexxy-editor", minimum: 2
    assert_select "form[action='/shots'][method='get']"
    assert_select "form[data-journal-target='search'] button[data-journal-target='undo'][class~='hidden!']"
    assert_select "[data-revert], [data-action='journal#retry']", count: 0
    assert_select "[data-push-notifications-target='bell']"
  end

  test "all journal columns are available without lazy SQL loads" do
    @user.update!(shot_metadata_fields: %w[basket water])
    journal = Journal.new(@user)
    shots, = journal.page(journal.scope, {})
    queries = []
    capture = ->(*args) { queries << args.last[:sql] unless args.last[:name] == "SCHEMA" }
    ActiveSupport::Notifications.subscribed(capture, "sql.active_record") do
      shots.each do |shot|
        journal.columns.each_key { journal.value(shot, it) }
        shot.manual?
      end
    end
    assert_empty queries
  end

  test "single and batch changes preserve notes and undo exact coffee fields" do
    @user.update!(coffee_management_enabled: true)
    roaster = create(:roaster, user: @user)
    bag = create(:coffee_bag, roaster:)
    other = create(:shot, user: @user, bean_brand: "Original", roast_date: "2026-01-01")
    original = [@shot, other].map { it.attributes.slice(*Journal::COFFEE_FIELDS) }

    patch journal_url, params: {changes: [change(@shot, coffee_bag_id: bag.id), change(other, coffee_bag_id: bag.id)]}, as: :json
    assert_response :success
    undo = response.parsed_body.fetch("undo")
    assert_equal bag.id, @shot.reload.coffee_bag_id
    assert_equal "18", @shot.bean_weight
    assert_equal "<p><strong>Sweet</strong></p>", @shot.rich_text_html(:espresso_notes)

    patch journal_url, params: {undo:}, as: :json
    assert_response :success
    assert_equal original, [@shot, other].map { it.reload.attributes.slice(*Journal::COFFEE_FIELDS) }
  end

  test "batch is atomic including tag assignments" do
    other = create(:shot, user: @user)
    patch journal_url, params: {changes: [change(@shot, tag_list: "test", bean_weight: "20"), change(other, acidity: 99)]}, as: :json
    assert_response :unprocessable_entity
    assert_equal "18", @shot.reload.bean_weight
    assert_empty @shot.tags
    assert_empty @user.tags
  end

  test "stale edits and stale undo do not overwrite new values" do
    stale = change(@shot, bean_weight: "20")
    @shot.update!(bean_weight: "19")
    patch journal_url, params: {changes: [stale]}, as: :json
    assert_response :conflict
    assert_equal "19", @shot.reload.bean_weight

    patch journal_url, params: {changes: [change(@shot, bean_weight: "21")]}, as: :json
    undo = response.parsed_body.fetch("undo")
    @shot.update!(bean_weight: "22")
    patch journal_url, params: {undo:}, as: :json
    assert_response :conflict
    assert_equal "22", @shot.reload.bean_weight
  end

  test "foreign shots and coffee bags are rejected" do
    foreign = create(:shot)
    patch journal_url, params: {changes: [change(@shot, bean_weight: "20"), change(foreign, bean_weight: "20")]}, as: :json
    assert_response :not_found
    assert_equal "18", @shot.reload.bean_weight

    @user.update!(coffee_management_enabled: true)
    bag = create(:coffee_bag)
    patch journal_url, params: {changes: [change(@shot, coffee_bag_id: bag.id)]}, as: :json
    assert_response :not_found
  end

  test "free users can search but cannot access old shots or premium fields" do
    @shot.update!(created_at: 2.months.ago)
    recent = create(:shot, user: @user, profile_title: "Matching brew", start_time: 1.year.ago)
    @user.update!(premium_expires_at: nil)
    get shots_url(q: "Matching")
    assert_response :success
    assert_select "tr[data-shot-id='#{recent.id}']"
    assert_select "tr[data-shot-id='#{@shot.id}']", count: 0
    assert_select "[data-column='private_notes']", count: 0
    assert_select "form[data-action*='journal#search']", count: 0

    patch journal_url, params: {changes: [change(@shot, bean_weight: "20")]}, as: :json
    assert_response :not_found
    patch journal_url, params: {changes: [change(recent, private_notes: "Secret")]}, as: :json
    assert_response :unprocessable_entity
  end

  test "clearing and metadata merge preserve untouched values" do
    @user.update!(shot_metadata_fields: %w[basket water])
    @shot.update!(metadata: {basket: "VST", water: "soft"})
    patch journal_url, params: {changes: [change(@shot, bean_weight: "", metadata: {basket: "IMS"})]}, as: :json
    assert_response :success
    assert_equal "", @shot.reload.bean_weight
    assert_equal({"basket" => "IMS", "water" => "soft"}, @shot.metadata)
    assert_equal "<p><strong>Sweet</strong></p>", @shot.rich_text_html(:espresso_notes)
  end

  test "undo removes a newly added metadata key and preserves unrelated edits" do
    @user.update!(shot_metadata_fields: %w[basket water])
    @shot.update!(metadata: {water: "soft"})
    patch journal_url, params: {changes: [change(@shot, metadata: {basket: "IMS"})]}, as: :json
    assert_response :success
    undo = response.parsed_body.fetch("undo")
    @shot.reload.update!(metadata: @shot.metadata.merge("water" => "hard"))
    patch journal_url, params: {undo:}, as: :json
    assert_response :success
    assert_equal({"water" => "hard"}, @shot.reload.metadata)
  end

  test "multiple signed changes can be undone in reverse order" do
    undos = []
    %w[19 20 21].each do |value|
      patch journal_url, params: {changes: [change(@shot, bean_weight: value)]}, as: :json
      assert_response :success
      undos << response.parsed_body.fetch("undo")
    end
    undos.reverse.zip(%w[20 19 18]).each do |undo, expected|
      patch journal_url, params: {undo:}, as: :json
      assert_response :success
      assert_equal expected, @shot.reload.bean_weight
    end
  end

  test "manual creation is retry safe supports backdating and requires no telemetry" do
    id = SecureRandom.uuid
    attributes = {start_time: "2026-01-01T08:30:00", bean_weight: "18", espresso_notes: "<p>Peach</p>"}
    assert_difference "@user.shots.count", 1 do
      2.times do
        post shots_url, params: {entry_id: id, shot: attributes}, as: :json
        assert_response :created
      end
    end
    shot = @user.shots.find(id)
    assert shot.manual?
    assert_nil shot.information
    assert_nil shot.duration
    assert_equal Time.utc(2026, 1, 1, 7, 30), shot.start_time
    assert shot.sha.present?

    patch journal_url, params: {changes: [change(shot, duration: "30.5", start_time: "2026-01-02T09:00:00")]}, as: :json
    assert_response :success
    assert_equal 30.5, shot.reload.duration
    get shot_url(shot)
    assert_response :success
    get shots_url
    assert_response :success
    get api_shot_url(shot, format: :json)
    assert_response :success
    get api_shot_profile_url(shot, format: :json)
    assert_response :unprocessable_content
  end

  test "creation replay with changed values conflicts rather than discarding changes" do
    id = SecureRandom.uuid
    post shots_url, params: {entry_id: id, shot: {bean_weight: "18"}}, as: :json
    assert_response :created
    assert_no_difference "Shot.count" do
      post shots_url, params: {entry_id: id, shot: {bean_weight: "19"}}, as: :json
      assert_response :conflict
    end
    assert_equal id, response.parsed_body.fetch("shot_id")
    assert_equal "18", @user.shots.find(id).bean_weight
  end

  test "creation returns matching count and identifies a pinned nonmatching row" do
    post shots_url, params: {entry_id: SecureRandom.uuid, shot: {bean_type: "Gesha"}, query: {q: "Gesha"}}, as: :json
    assert_response :created
    assert_equal 1, response.parsed_body.fetch("count")
    assert response.parsed_body.fetch("matches")
    post shots_url, params: {entry_id: SecureRandom.uuid, shot: {bean_type: "Bourbon"}, query: {q: "Gesha"}}, as: :json
    assert_response :created
    assert_equal 1, response.parsed_body.fetch("count")
    assert_not response.parsed_body.fetch("matches")
  end

  test "manual creation without duration renders existing shot views" do
    post shots_url, params: {entry_id: SecureRandom.uuid, shot: {bean_weight: "18"}}, as: :json
    assert_response :created
    id = response.parsed_body.fetch("rows").first.fetch("id")
    get shot_url(id)
    assert_response :success
    get shots_url
    assert_response :success
  end

  test "invalid manual inputs and imported date edits are rejected" do
    [{start_time: "bad"}, {duration: "-1"}, {duration: "no"}, {espresso_enjoyment: "101"}].each do |attributes|
      assert_no_difference "Shot.count" do
        post shots_url, params: {entry_id: SecureRandom.uuid, shot: attributes}, as: :json
        assert_response :unprocessable_entity
      end
    end
    patch journal_url, params: {changes: [change(@shot, start_time: Time.current.iso8601)]}, as: :json
    assert_response :unprocessable_entity
  end

  test "column preferences are account scoped and validated" do
    patch profile_journal_columns_url, params: {columns: {order: %w[coffee start_time], hidden: %w[duration]}}, as: :json
    assert_response :no_content
    assert_equal %w[coffee start_time], @user.reload.journal_columns["order"]
    get shots_url
    assert_select "th[data-column='duration'].hidden"
    patch profile_journal_columns_url, params: {columns: {order: ["user_id"], hidden: []}}, as: :json
    assert_response :unprocessable_entity
    patch profile_journal_columns_url, params: {columns: nil}, as: :json
    assert_response :success
    assert_nil @user.reload[:journal_columns]
    assert_equal Journal::DEFAULT_COLUMNS, response.parsed_body.fetch("visible")
    get shots_url
    assert_response :success
    assert_equal Journal::DEFAULT_COLUMNS, Journal.new(@user.reload).visible_columns
    assert_equal "espresso_enjoyment", css_select("thead th[data-column]").first["data-column"]
  end

  test "preference defaults off and switches interface at same URL" do
    assert_not User.new.journal_enabled?
    delete session_url
    sign_in(@user)
    assert_redirected_to shots_url
    get edit_profile_url
    assert_select "input[name='user[journal_enabled]'][checked]"
    patch profile_url, params: {user: {journal_enabled: "0"}}
    assert_redirected_to shots_path(format: :html)
    assert_not @user.reload.journal_enabled?
    get shots_url
    assert_select "[data-controller~='journal']", count: 0
    patch profile_url, params: {user: {journal_enabled: "1"}}
    assert_redirected_to shots_path(format: :html)
    follow_redirect!
    assert_response :success
    assert_select "[data-controller~='journal']"
    assert_select "a[href='/shots'].border-terracotta-500", text: "Shots"
  end

  test "guests cannot read or write journal" do
    delete session_url
    get shots_url
    assert_redirected_to new_session_url
    patch journal_url, params: {changes: [change(@shot, bean_weight: "20")]}, as: :json
    assert_redirected_to new_session_url
    assert_equal "18", @shot.reload.bean_weight
  end

  test "Turbo profile save redirects to HTML shots view with notice" do
    headers = {"Accept" => "text/vnd.turbo-stream.html, text/html"}
    patch(profile_url, params: {user: {skin: "Dark"}}, headers:)
    assert_redirected_to shots_path(format: :html)
    assert_equal "Dark", @user.reload.skin
    follow_redirect!(headers:)
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_includes response.body, "Profile successfully updated."
    assert_select "[data-controller~='journal']"
  end

  test "malformed changes and duplicate ids are rejected" do
    [[], {}, ["bad"], [change(@shot, bean_weight: "20")] * 2].each do |changes|
      patch journal_url, params: {changes:}, as: :json
      assert_response :unprocessable_entity
    end
  end

  test "undo of one field preserves later edits to other fields" do
    patch journal_url, params: {changes: [change(@shot, bean_weight: "20")]}, as: :json
    assert_response :success
    undo = response.parsed_body.fetch("undo")
    patch journal_url, params: {changes: [change(@shot, drink_weight: "42")]}, as: :json
    assert_response :success
    patch journal_url, params: {undo:}, as: :json
    assert_response :success
    assert_equal "18", @shot.reload.bean_weight
    assert_equal "42", @shot.drink_weight
  end

  test "rich notes can be saved cleared and reverted without formatting loss" do
    patch journal_url, params: {changes: [change(@shot, espresso_notes: "<p><em>Peach</em></p>")]}, as: :json
    assert_response :success
    patch journal_url, params: {changes: [change(@shot, espresso_notes: "")]}, as: :json
    assert_response :success
    undo = response.parsed_body.fetch("undo")
    assert_nil @shot.reload.rich_text_html(:espresso_notes)
    patch journal_url, params: {undo:}, as: :json
    assert_response :success
    assert_equal "<p><em>Peach</em></p>", @shot.reload.rich_text_html(:espresso_notes)
  end

  test "manual shots respect free daily creation limit" do
    @user.update!(premium_expires_at: nil)
    create_list(:shot, Shot::DAILY_LIMIT - 1, user: @user)
    assert_no_difference "Shot.count" do
      post shots_url, params: {entry_id: SecureRandom.uuid, shot: {bean_weight: "18"}}, as: :json
      assert_response :unprocessable_content
    end
  end

  test "backdating manual shots does not bypass daily creation limit" do
    @user.update!(premium_expires_at: nil)
    create_list(:shot, Shot::DAILY_LIMIT - 1, user: @user, start_time: 1.year.ago)
    assert_no_difference "Shot.count" do
      post shots_url, params: {entry_id: SecureRandom.uuid, shot: {start_time: 1.year.ago.iso8601}}, as: :json
      assert_response :unprocessable_content
    end
  end

  test "infinite loading handles tied timestamps" do
    timestamp = Time.current.change(usec: 0)
    @shot.update!(start_time: timestamp)
    create_list(:shot, Journal::PAGE_SIZE + 1, user: @user, start_time: timestamp)
    get shots_url
    first_ids = css_select("tr[data-shot-id]").pluck("data-shot-id")
    assert_equal Journal::PAGE_SIZE, first_ids.size
    next_url = css_select("turbo-frame#cursor").first["src"]
    assert next_url.present?
    cursor = Rack::Utils.parse_query(URI.parse(next_url).query)
    assert_equal timestamp.utc.iso8601(6), cursor.fetch("before")
    assert_equal first_ids.last, cursor.fetch("before_id")
    get next_url
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='append'][target='journal-rows']"
    assert_select "turbo-stream[data-journal-search-id='#{cursor.fetch('journal_search_id')}']", count: 4
    second_ids = css_select("tr[data-shot-id]").pluck("data-shot-id")
    assert_empty(first_ids & second_ids)
    assert_equal @user.shots.count, (first_ids + second_ids).size
  end

  test "fresh searches render HTML rows inside generation-tagged streams" do
    search_id = SecureRandom.uuid
    get shots_url(format: :turbo_stream, fresh_search: "1", journal_search_id: search_id)
    assert_response :success
    assert_select "turbo-stream[action='update'][target='journal-rows'][data-journal-search-id='#{search_id}'][data-journal-fresh-search='true']"
    assert_select "tr[data-shot-id='#{@shot.id}']"
  end

  test "premium search is instant and enjoyment is first by default" do
    get shots_url
    assert_select "form[data-action*='input->journal#search']"
    assert_equal "espresso_enjoyment", css_select("thead th[data-column]").first["data-column"]
    assert_select "th", text: "Details", count: 0
    assert_select "select[name='sort'], select[name='direction'], input[type='submit'][value='Search']", count: 0
  end

  test "single search combines coffee and tags without matching brew timestamps" do
    shot = create(:shot, user: @user, bean_type: "Gesha", start_time: Time.utc(2026, 9, 17, 22, 15), tag_list: "daily")
    get shots_url(q: "Gesha daily")
    assert_response :success
    assert_select "tr[data-shot-id='#{shot.id}']"
    assert_select "tr[data-shot-id='#{@shot.id}']", count: 0
    assert_select "form[data-journal-target='search'] [name='start_date'], form[data-journal-target='search'] [name='coffee_bag'], form[data-journal-target='search'] [name='tags']", count: 0
    get shots_url(q: "Gesha daily 2026-09-17")
    assert_response :success
    assert_select "tr[data-shot-id]", count: 0
  end

  private

  def change(shot, **attributes)
    {id: shot.id, version: shot.reload.updated_at.utc.iso8601(6), attributes:}
  end
end
