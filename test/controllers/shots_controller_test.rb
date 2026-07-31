require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user, :premium)
    @shot = create(:shot, user: @user)
    sign_in(@user)
  end

  test "rich notes use Lexxy and persist HTML" do
    @shot.update!(bean_notes: "<p><strong>Before</strong></p>")

    get edit_shot_url(@shot)

    assert_response :success
    assert_select "lexxy-editor[name='shot[bean_notes]']"
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
