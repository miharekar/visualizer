require "test_helper"

class ShotsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user)
    @shot = create(:shot, user: @user)
    sign_in(@user)
  end

  test "rich notes use Lexxy and persist HTML" do
    @shot.update_columns(bean_notes: "**Before**") # rubocop:disable Rails/SkipsModelValidations

    get edit_shot_url(@shot)

    assert_response :success
    assert_select "lexxy-editor[name='shot[bean_notes]']"
    assert_includes response.body, "&lt;strong&gt;Before&lt;/strong&gt;"

    patch shot_url(@shot), params: {shot: {bean_notes: "<p><strong>Chocolate</strong></p>"}}

    assert_redirected_to shot_url(@shot)
    assert_includes @shot.reload.bean_notes.to_s, "<strong>Chocolate</strong>"
  end

  test "filters rich text notes through plain text shadow column" do
    user = create(:user, :premium)
    matching = create(:shot, user:, profile_title: "Matching shot", bean_notes: "<p><strong>Chocolate</strong> and caramel</p>")
    create(:shot, user:, profile_title: "Other shot", bean_notes: "<p>Floral</p>")
    sign_in(user)

    get shots_url, params: {bean_notes: "Chocolate and caramel"}

    assert_response :success
    assert_includes response.body, matching.profile_title
    assert_not_includes response.body, "Other shot"
  end
end
