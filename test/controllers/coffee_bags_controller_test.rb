require "test_helper"

class CoffeeBagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    host! "example.com"
    @user = create(:user, :premium)
    @roaster = create(:roaster, user: @user)
    @coffee_bag = create(:coffee_bag, roaster: @roaster, notes: "<p><strong>Before</strong></p>")
    sign_in(@user)
  end

  test "rich notes use Lexxy and persist HTML" do
    get edit_coffee_bag_url(@coffee_bag)

    assert_response :success
    assert_select "lexxy-editor[name='coffee_bag[notes]']"
    assert_includes response.body, "&lt;strong&gt;Before&lt;/strong&gt;"

    patch coffee_bag_url(@coffee_bag), params: {coffee_bag: {name: @coffee_bag.name, roaster_id: @roaster.id, notes: "<p><strong>Chocolate</strong></p>"}}

    assert_redirected_to coffee_bags_url(format: :html)
    assert_equal "<p><strong>Chocolate</strong></p>", @coffee_bag.reload.rich_text_html(:notes)
  end
end
