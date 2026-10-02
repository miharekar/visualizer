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
end
