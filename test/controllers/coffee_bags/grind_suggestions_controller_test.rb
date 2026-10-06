require "test_helper"

class CoffeeBags::GrindSuggestionsControllerTest < ActionDispatch::IntegrationTest
  test "suggests grind and replaces the link" do
    admin = create(:user, :admin, :with_coffee_management)
    roaster = create(:roaster, user: admin)
    create(:shot, user: admin, coffee_bag: create(:coffee_bag, roaster:, name: "Kenya"), profile_title: "Adaptive", grinder_model: "EG-1", grinder_setting: "1.2")
    bag = create(:coffee_bag, roaster:, name: "Ethiopia")
    probabilities = (0..4).to_h { [it.to_s, it == 1 ? 1.0 : 0.0] }
    stub_request(:post, SystemOne::API_ENDPOINT).to_return(status: 200, body: {result: {model: "clef", answers: {relative_0: {type: "score", probabilities:}}}, success: true}.to_json)
    sign_in admin

    post coffee_bag_grind_suggestion_path(bag), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Adaptive"
    assert_includes response.body, "1.2 on EG-1 (Slightly finer than Kenya)"
  end

  test "index hides grind suggestions until the user has shots" do
    admin = create(:user, :admin, :with_coffee_management)
    create(:coffee_bag, roaster: create(:roaster, user: admin))
    sign_in admin

    get coffee_bags_path
    assert_not_includes response.body, "Suggest grind"

    create(:shot, user: admin, profile_title: "Adaptive")
    get coffee_bags_path
    assert_includes response.body, "Suggest grind"
  end

  test "non-admins are redirected" do
    user = create(:user, :with_coffee_management)
    bag = create(:coffee_bag, roaster: create(:roaster, user:))
    sign_in user

    post coffee_bag_grind_suggestion_path(bag), as: :turbo_stream

    assert_redirected_to shots_path
    assert_nil bag.reload.grind_suggestion
  end
end
