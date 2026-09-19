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

  test "initial index renders framed results and only visible cells without morphing" do
    get shots_url
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "turbo-frame#journal-editor", count: 1
    assert_select "turbo-frame#journal-results", count: 1
    assert_select "#journal-results > div.relative.overflow-auto", count: 1
    assert_select "[data-journal-selection-target='toolbar'].fixed", count: 1
    assert_select "#journal-columns-panel input[type='checkbox']", count: 0
    assert_select "#journal-columns-panel button[data-action='journal-columns#cancel']", text: "Cancel"
    assert_select "#journal-columns-panel button[data-action='journal-columns#reset']", text: "Reset to defaults"
    assert_select "#journal-columns-panel [data-action*='keydown']", count: 0
    assert_select "#journal-columns-panel [data-journal-columns-target='list'][data-hidden='false']", count: 1
    assert_select "#journal-columns-panel [data-journal-columns-target='list'][data-hidden='true']", count: 1
    assert_select "form[action='#{shots_path}'][method='get'][data-turbo-frame='journal-results'] input[name='q']"
    assert_select "form[action='#{edit_journal_path}'][method='get'][data-turbo-frame='journal-editor']"
    assert_select "turbo-frame#journal-results tr#journal-shot-#{@shot.id}" do
      assert_equal Journal.new(@user).visible_columns, css_select("td[data-column]").pluck("data-column")
      Journal.new(@user).visible_columns.each do |field|
        assert_select "turbo-frame##{cell_id(@shot, field)}", count: 1
      end
    end
    assert_select "td[data-column='espresso_notes'], td[data-column='private_notes'], td[data-column='tag_list']", count: 0
    assert_select "[method='morph'], [refresh='morph'], meta[name='turbo-refresh-method'][content='morph']", count: 0
  end

  test "GET searches return HTML results and pagination targets their search scoped IDs" do
    matching = create_list(:shot, Journal::PAGE_SIZE + 1, user: @user, bean_type: "Gesha")
    get shots_url, params: {q: "Gesha"}, headers: {"Turbo-Frame" => "journal-results"}
    assert_response :success
    assert_equal "text/html", response.media_type
    assert_select "turbo-frame#journal-results", count: 1
    assert_select "turbo-stream[action='append']", count: 0
    assert_select "tr#journal-shot-#{@shot.id}", count: 0
    first_ids = css_select("tbody tr").pluck("id")
    assert_equal Journal::PAGE_SIZE, first_ids.size
    rows_id = css_select("tbody").first["id"]
    cursor = css_select("turbo-frame[id^='journal-cursor-']").first
    cursor_id = cursor["id"]
    next_url = cursor["src"]
    query = Rack::Utils.parse_query(URI.parse(next_url).query)
    assert_equal "Gesha", query.fetch("q")
    assert_equal "journal-rows-#{query.fetch('journal_search_id')}", rows_id
    assert_equal "journal-cursor-#{query.fetch('journal_search_id')}", cursor_id

    get shots_url, params: {q: "No matching coffee"}, headers: {"Turbo-Frame" => "journal-results"}
    assert_response :success
    new_rows_id = css_select("tbody").first["id"]
    assert_not_equal rows_id, new_rows_id
    assert_select "turbo-frame#journal-results tbody tr", count: 0

    get next_url, headers: {"Turbo-Frame" => cursor_id}
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream", count: 2
    assert_select "turbo-stream[action='append'][target='#{rows_id}']", count: 1
    assert_select "turbo-stream[action='replace'][target='#{cursor_id}']", count: 1
    assert_select "turbo-stream[target='#{new_rows_id}'], turbo-stream[target='journal-rows']", count: 0
    assert_select "turbo-frame##{cursor_id}[src]", count: 0
    second_ids = css_select("tr").pluck("id")
    assert_empty first_ids & second_ids
    assert_equal matching.map { "journal-shot-#{it.id}" }.sort, (first_ids + second_ids).sort
  end

  test "editor loads owned shots and cancel returns an empty frame" do
    get edit_journal_url, params: {ids: [@shot.id], field: "espresso_notes"}
    assert_response :success
    assert_select "turbo-frame#journal-editor"
    assert_select "turbo-frame#journal-editor dialog[data-controller='journal-dialog']" do
      assert_select "form .flex.justify-end > button[data-action='journal-dialog#close'] + input[type='submit']"
      assert_select "form[action='#{journal_path}']"
    end
    assert_includes response.body, "Sweet"

    get edit_journal_url
    assert_response :success
    assert_select "turbo-frame#journal-editor" do |frames|
      assert_empty frames.first.text.strip
    end
    get edit_journal_url, params: {ids: [create(:shot).id], field: "espresso_notes"}
    assert_response :not_found
  end

  test "cell updates only submitted field and dependent ratio" do
    update_field("bean_weight", "20")
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='update'][target='#{cell_id(@shot, 'bean_weight')}']"
    assert_select "turbo-stream[action='update'][target='#{cell_id(@shot, 'ratio')}']"
    assert_select "turbo-stream[target='#{cell_id(@shot, 'drink_weight')}']", count: 0
    assert_select "turbo-stream[action='replace']", count: 0
    assert_equal "20", @shot.reload.bean_weight
    assert_equal "<p><strong>Sweet</strong></p>", @shot.rich_text_html(:espresso_notes)
  end

  test "coffee and grinder dropdowns can overflow their dialog" do
    @user.update!(coffee_management_enabled: true)
    %w[coffee grinder_model].each do |field|
      get edit_journal_url, params: {ids: [@shot.id], field:}
      assert_response :success
      assert_select "dialog.overflow-visible [data-combobox-target='list']"
    end
  end

  test "same field is last write wins and neighboring edits survive" do
    @shot.update!(bean_weight: "19", drink_weight: "42")
    update_field("bean_weight", "20")
    assert_response :success
    update_field("bean_weight", "21")
    assert_response :success
    assert_equal "21", @shot.reload.bean_weight
    assert_equal "42", @shot.drink_weight
  end

  test "invalid cell keeps attempted value and returns a direct 422 stream" do
    update_field("espresso_enjoyment", "101")
    assert_response :unprocessable_content
    assert_equal "text/vnd.turbo-stream.html", response.media_type
    assert_select "turbo-stream[action='update'][target='#{cell_id(@shot, 'espresso_enjoyment')}']"
    assert_includes response.body, "101"
    assert_includes response.body, "Enjoyment must be between 0 and 100"
  end

  test "editor bulk save clears editor and preserves unrelated fields" do
    other = create(:shot, user: @user)
    update_field("tag_list", "daily", ids: [@shot.id, other.id], editor: true)
    assert_response :success
    assert_select "turbo-stream[action='update'][target='journal-editor']"
    assert_equal "daily", @shot.reload.tag_list
    assert_equal "daily", other.reload.tag_list
    assert_equal "18", @shot.bean_weight
  end

  test "invalid editor save renders its attempted value in a replacement dialog" do
    update_field("espresso_enjoyment", "101", editor: true)
    assert_response :unprocessable_content
    assert_select "turbo-stream[action='replace'][target='journal-editor'] dialog" do
      assert_select "input[name='value'][value='101']"
      assert_select "p", text: /Enjoyment must be between 0 and 100/
    end
  end

  test "bulk tags editor starts with the shared intersection" do
    @shot.update!(tag_list: "sweet,daily,first")
    other = create(:shot, user: @user, tag_list: "daily,sweet,second")
    get edit_journal_url, params: {ids: [@shot.id, other.id], field: "tag_list"}, headers: {"Turbo-Frame" => "journal-editor"}
    assert_response :success
    assert_select "turbo-frame#journal-editor input[name='value'][value='daily,sweet']"
    assert_select "input[name='ids[]']", count: 2

    other.update!(tag_list: "second")
    get edit_journal_url, params: {ids: [@shot.id, other.id], field: "tag_list"}
    assert_response :success
    assert_equal "", css_select("input[name='value']").first["value"].to_s
    assert_equal "daily,first,sweet", @shot.reload.tag_list
    assert_equal "second", other.reload.tag_list
  end

  test "bulk transaction rolls back eager tag assignments and earlier shots" do
    other = create(:shot, user: @user)
    first, last = [@shot, other].sort_by(&:id)
    last.update_columns(acidity: 99) # rubocop:disable Rails/SkipsModelValidations -- exercise rollback when a later shot fails validation
    assert_raises ActiveRecord::RecordInvalid do
      Journal.new(@user).update([first.id, last.id], {tag_list: "test", bean_weight: "20"})
    end
    assert_equal "18", @shot.reload.bean_weight
    assert_empty first.reload.tags
    assert_empty last.reload.tags
    assert_empty @user.tags
  end

  test "bulk imported restriction rolls back manual shot changes" do
    manual = create(:shot, user: @user)
    original = manual.reload.start_time
    update_field("start_time", "2026-01-01T08:30:00", ids: [manual.id, @shot.id], editor: true)
    assert_response :unprocessable_content
    assert_equal original, manual.reload.start_time
  end

  test "foreign shots and coffee bags are rejected" do
    update_field("bean_weight", "20", ids: [@shot.id, create(:shot).id])
    assert_response :not_found
    assert_equal "18", @shot.reload.bean_weight

    @user.update!(coffee_management_enabled: true)
    patch journal_url, params: {ids: [@shot.id], field: "coffee", attributes: {coffee_bag_id: create(:coffee_bag).id}, editor: true}, headers: stream_headers
    assert_response :not_found
  end

  test "coffee saves refresh bag fields and their cells" do
    @user.update!(coffee_management_enabled: true)
    bag = create(:coffee_bag, roaster: create(:roaster, user: @user))
    patch journal_url, params: {ids: [@shot.id], field: "coffee", attributes: {coffee_bag_id: bag.id}, editor: true}, headers: stream_headers
    assert_response :success
    assert_equal bag.id, @shot.reload.coffee_bag_id
    assert_equal bag.name, @shot.bean_type
    assert_select "turbo-stream[action='update'][target='#{cell_id(@shot, 'coffee')}']"
    assert_select "turbo-stream[action='update'][target='#{cell_id(@shot, 'roast_date')}']"
    assert_select "turbo-stream[target='#{cell_id(@shot, 'bean_weight')}']", count: 0
    assert_equal "#{@shot.bean_type} - #{@shot.bean_brand} (#{@shot.roast_date})", Journal.new(@user).value(@shot, "coffee")
    update_field("bean_brand", "Override")
    assert_response :unprocessable_content
  end

  test "unmanaged coffee field edits clear canonical association without overwriting neighboring fields" do
    roaster = CanonicalRoaster.create!(name: "Original roaster")
    bag = CanonicalCoffeeBag.create!(name: "Original coffee", canonical_roaster: roaster)
    assert_not @user.coffee_management_enabled?
    %w[bean_brand bean_type].each do |field|
      @shot.update!(canonical_coffee_bag: bag)
      neighbor = field == "bean_brand" ? "bean_type" : "bean_brand"
      original_neighbor = @shot.public_send(neighbor)
      update_field(field, "Custom #{field}", editor: true)
      assert_response :success
      assert_nil @shot.reload.canonical_coffee_bag_id
      assert_equal "Custom #{field}", @shot.public_send(field)
      assert_equal original_neighbor, @shot.public_send(neighbor)
      assert_equal "18", @shot.bean_weight
    end
  end

  test "free users cannot access old shots or premium fields" do
    @shot.update!(created_at: 2.months.ago)
    recent = create(:shot, user: @user, profile_title: "Matching brew", start_time: 1.year.ago)
    @user.update!(premium_expires_at: nil)
    assert_equal [recent.id], Journal.new(@user).search(q: "Matching").pluck(:id)
    update_field("bean_weight", "20")
    assert_response :not_found
    update_field("private_notes", "Secret", ids: [recent.id])
    assert_response :unprocessable_content
    get edit_journal_url, params: {ids: [recent.id], field: "private_notes"}
    assert_response :unprocessable_content
  end

  test "clearing and metadata merge preserve untouched values" do
    @user.update!(shot_metadata_fields: %w[basket water])
    @shot.update!(metadata: {basket: "VST", water: "soft"})
    update_field("metadata:basket", "IMS")
    assert_response :success
    update_field("bean_weight", "")
    assert_response :success
    assert_equal "", @shot.reload.bean_weight
    assert_equal({"basket" => "IMS", "water" => "soft"}, @shot.metadata)
    update_field("metadata:unknown", "bad")
    assert_response :unprocessable_content
    assert_equal({"basket" => "IMS", "water" => "soft"}, @shot.reload.metadata)
  end

  test "rich notes retain formatting and can be cleared" do
    update_field("espresso_notes", "<p><em>Peach</em></p>", editor: true)
    assert_response :success
    assert_equal "<p><em>Peach</em></p>", @shot.reload.rich_text_html(:espresso_notes)
    update_field("espresso_notes", "", editor: true)
    assert_response :success
    assert_nil @shot.reload.rich_text_html(:espresso_notes)
  end

  test "manual date and duration edits validate input" do
    manual = create(:shot, user: @user)
    update_field("start_time", "2026-01-01T08:30:00", ids: [manual.id])
    assert_response :success
    assert_equal Time.utc(2026, 1, 1, 7, 30), manual.reload.start_time
    update_field("duration", "30.5", ids: [manual.id])
    assert_response :success
    assert_equal 30.5, manual.reload.duration
    %w[-1 no].each do |value|
      update_field("duration", value, ids: [manual.id])
      assert_response :unprocessable_content
    end
    update_field("start_time", "bad", ids: [manual.id])
    assert_response :unprocessable_content
    update_field("duration", "30")
    assert_response :unprocessable_content
  end

  test "column preferences accept forms and reset with redirects" do
    headers = {"Accept" => "text/vnd.turbo-stream.html, text/html"}
    patch(profile_journal_columns_url, params: {order: %w[bean_type start_time], hidden: %w[duration]}, headers:)
    assert_response :see_other
    assert_redirected_to shots_path(format: :html)
    assert_equal %w[bean_type start_time], @user.reload.journal_columns["order"]
    follow_redirect!(headers:)
    assert_equal "text/html", response.media_type
    assert_select "turbo-frame#journal-results table", count: 1
    assert_select "td[data-column='duration'], turbo-stream[action='append']", count: 0
    patch(profile_journal_columns_url, params: {order: ["user_id"]}, headers:)
    assert_redirected_to shots_path(format: :html)
    assert_equal "Unknown columns", flash[:alert]
    assert_equal %w[bean_type start_time], @user.reload.journal_columns["order"]
    patch(profile_journal_columns_url, params: {reset: "1"}, headers:)
    assert_response :see_other
    assert_redirected_to shots_path(format: :html)
    assert_nil @user.reload[:journal_columns]
    journal = Journal.new(@user)
    assert_equal journal.default_columns, journal.visible_columns
    follow_redirect!(headers:)
    assert_equal "text/html", response.media_type
    assert_select "turbo-frame#journal-results td[data-column='duration']", count: 1
    assert_select "turbo-stream[action='append']", count: 0
  end

  test "column defaults follow coffee management mode" do
    assert_equal %w[espresso_enjoyment start_time bean_brand bean_type profile_title bean_weight grinder_setting grinder_model drink_weight duration actions], Journal.new(@user).default_columns
    @user.update!(coffee_management_enabled: true)
    assert_equal %w[espresso_enjoyment start_time coffee profile_title bean_weight grinder_setting grinder_model drink_weight duration actions], Journal.new(@user).default_columns
  end

  test "guests cannot read or write journal" do
    delete session_url
    get edit_journal_url, params: {ids: [@shot.id], field: "espresso_notes"}
    assert_redirected_to new_session_url
    update_field("bean_weight", "20")
    assert_redirected_to new_session_url
    assert_equal "18", @shot.reload.bean_weight
  end

  test "malformed duplicate and oversized selections are rejected" do
    [[], "bad", [@shot.id] * 2, ["bad"], Array.new(Journal::MAX_BATCH + 1) { SecureRandom.uuid }].each do |ids|
      update_field("bean_weight", "20", ids:)
      assert_response :unprocessable_content
    end
  end

  test "list loads full shot columns without telemetry or unused associations" do
    journal = Journal.new(@user)
    shots, = journal.page(journal.scope, {})
    shot = shots.first
    assert shot.has_attribute?(:barista)
    assert shot.has_attribute?(:espresso_notes)
    assert shot.has_attribute?(:metadata)
    assert_not shot.association(:rich_text_espresso_notes).loaded?
    assert_not shot.association(:tags).loaded?
    assert_not shot.association(:image_attachment).loaded?
    assert_not shot.association(:information).loaded?
    assert_not shot.manual?
  end

  test "visible rich text tags and images are preloaded without lazy SQL" do
    @user.update!(shot_metadata_fields: %w[basket water])
    journal = Journal.new(@user)
    @user.update!(journal_columns: {order: journal.columns.keys, hidden: []})
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

  test "cursor pagination handles tied timestamps" do
    timestamp = Time.current.change(usec: 0)
    @shot.update!(start_time: timestamp)
    create_list(:shot, Journal::PAGE_SIZE + 1, user: @user, start_time: timestamp)
    journal = Journal.new(@user)
    first, cursor = journal.page(journal.scope, {})
    assert_equal Journal::PAGE_SIZE, first.size
    assert_equal timestamp.utc.iso8601(6), cursor.fetch(:before)
    assert_equal first.last.id, cursor.fetch(:before_id)
    second, cursor = journal.page(journal.scope, cursor)
    assert_nil cursor
    assert_empty(first.map(&:id) & second.map(&:id))
    assert_equal @user.shots.count, (first + second).size
    assert_raises(Journal::InvalidChange) { journal.page(journal.scope, before: "bad", before_id: @shot.id) }
  end

  test "search combines coffee and tags without matching brew timestamps" do
    shot = create(:shot, user: @user, bean_type: "Gesha", start_time: Time.utc(2026, 9, 17, 22, 15), tag_list: "daily")
    journal = Journal.new(@user)
    assert_equal [shot.id], journal.search(q: "Gesha daily").pluck(:id)
    assert_empty journal.search(q: "Gesha daily 2026-09-17")
  end

  private

  def stream_headers
    {"Accept" => "text/vnd.turbo-stream.html"}
  end

  def update_field(field, value, ids: [@shot.id], editor: false)
    patch journal_url, params: {ids:, field:, value:, editor:}, headers: stream_headers
  end

  def cell_id(shot, field)
    ApplicationController.helpers.journal_cell_id(shot, field)
  end
end
