require "test_helper"

class Shots::GrindSuggestionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @shot = create(:shot, user: @admin, duration: 30, grinder_setting: "15")
  end

  test "suggests grind and replaces the link" do
    probabilities = (0..6).to_h { [it.to_s, it == 1 ? 1.0 : 0.0] }
    result = {model: "clef", answers: {adjustment: {type: "score", probabilities:}, puck_issue: {type: "noul", noul: 0.1}}}
    stub_request(:post, SystemOne::API_ENDPOINT).to_return(status: 200, body: {result:, success: true}.to_json)
    sign_in @admin

    post shot_grind_suggestion_path(@shot), as: :turbo_stream

    assert_response :success
    assert_includes response.body, "Finer"
    assert_equal "finer", @shot.reload.grind_suggestion["direction"]
  end

  test "non-admins are redirected" do
    user = create(:user, :premium)
    shot = create(:shot, user:, duration: 30)
    sign_in user

    post shot_grind_suggestion_path(shot), as: :turbo_stream

    assert_redirected_to shots_path
    assert_nil shot.reload.grind_suggestion
  end
end
