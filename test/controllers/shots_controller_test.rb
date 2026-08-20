require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  setup do
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
end
