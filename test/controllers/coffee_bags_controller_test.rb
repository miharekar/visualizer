require "test_helper"

class CoffeeBagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user, :premium)
    @roaster = create(:roaster, user: @user)
    @coffee_bag = create(:coffee_bag, roaster: @roaster)
    sign_in(@user)
  end

  test "rich notes use Lexxy and persist HTML" do
    @coffee_bag.update_columns(notes: "**Before**") # rubocop:disable Rails/SkipsModelValidations

    get edit_coffee_bag_url(@coffee_bag)

    assert_response :success
    assert_select "lexxy-editor[name='coffee_bag[notes]']"
    assert_includes response.body, "&lt;strong&gt;Before&lt;/strong&gt;"

    patch coffee_bag_url(@coffee_bag), params: {coffee_bag: {notes: "<p><strong>Chocolate</strong></p>"}}

    assert_redirected_to coffee_bags_url(format: :html)
    assert_includes @coffee_bag.reload.notes.to_s, "<strong>Chocolate</strong>"
  end
end
