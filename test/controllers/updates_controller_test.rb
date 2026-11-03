require "test_helper"

class UpdatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user, :admin)
    @update = Update.create!(title: "Lexxy", published_at: Time.current, body: "<p><strong>Before</strong></p>")
    sign_in(@user)
  end

  test "rich body renders, highlights, and persists through Lexxy" do
    get edit_update_url(@update)

    assert_response :success
    assert_select "lexxy-editor[name='update[body]'][attachments='true']"
    assert_includes response.body, "&lt;strong&gt;Before&lt;/strong&gt;"

    get update_url(@update)

    assert_response :success
    assert_select ".lexxy-content[data-controller='syntax-highlight']"

    patch update_url(@update), params: {update: {title: @update.title, published_at: @update.published_at, body: "<p><strong>After</strong></p>"}}

    assert_redirected_to update_url(@update.slug)
    assert_equal "<p><strong>After</strong></p>", @update.reload.body.body.to_html
  end

  test "pasted Markdown image attachment survives saving rendering and editing" do
    image_url = "https://example.com/update.png"
    body = %(<action-text-attachment url="#{image_url}" content-type="image/*" filename="update.png" alt="Update screenshot" presentation="gallery"></action-text-attachment>)

    patch update_url(@update), params: {update: {body:}}

    assert_redirected_to update_url(@update.slug)
    assert_includes @update.reload.body.body.to_html, image_url

    get update_url(@update)

    assert_response :success
    assert_select "img[src='#{image_url}']"

    get edit_update_url(@update)

    assert_response :success
    assert_select "lexxy-editor[attachments='true']"
    assert_includes response.body, image_url
  end

  test "feed carries the full body with absolute links" do
    @update.update!(body: %(<p><a href="/premium#journal">a</a> <a href="#fn:1">b</a> <a href="https://example.org/x">c</a> <a href="mailto:a@b.co">d</a></p><img src="/assets/premium/journal.png">))

    get feed_updates_url(format: :rss)

    assert_response :success
    encoded = Nokogiri::XML(response.body).at_xpath("//item/content:encoded", "content" => "http://purl.org/rss/1.0/modules/content/")
    body = Nokogiri::HTML5.fragment(encoded.text)

    assert_equal ["#{request.base_url}/premium#journal", "#{update_url(@update.slug)}#fn:1", "https://example.org/x", "mailto:a@b.co"], body.css("a").pluck("href")
    assert_equal "#{request.base_url}/assets/premium/journal.png", body.at_css("img")["src"]
  end

  test "feed is only rendered again after an update changes" do
    get feed_updates_url(format: :rss)
    etag = response.etag
    ActiveRecord::Base.connection.clear_query_cache

    assert_no_queries_match(/action_text_rich_texts/) do
      get feed_updates_url(format: :rss), headers: {"If-None-Match" => etag}
    end
    assert_response :not_modified

    @update.update!(body: "<p>After</p>")
    get feed_updates_url(format: :rss), headers: {"If-None-Match" => etag}

    assert_response :success
  end
end
