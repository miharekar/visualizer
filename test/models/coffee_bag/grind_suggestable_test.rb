require "test_helper"

class CoffeeBag::GrindSuggestableTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :admin, :with_coffee_management)
    @roaster = create(:roaster, user: @user)
    @kenya = create(:coffee_bag, roaster: @roaster, name: "Kenya", roast_level: "Light")
    @brazil = create(:coffee_bag, roaster: @roaster, name: "Brazil", roast_level: "Dark")
    create_shot(@kenya, "Adaptive", "1.2", enjoyment: 90, start_time: 3.days.ago)
    create_shot(@kenya, "Adaptive", "1.6", enjoyment: 40, start_time: 2.days.ago)
    create_shot(@brazil, "Adaptive", "2.4", start_time: 1.day.ago)
    create_shot(@brazil, "Blooming", "2.0", start_time: 1.day.ago)
  end

  test "enqueues suggestion for new admin bags only" do
    assert_enqueued_with(job: CoffeeBag::SuggestGrindJob) { create(:coffee_bag, roaster: @roaster, name: "New") }
    assert_no_enqueued_jobs(only: CoffeeBag::SuggestGrindJob) { create(:coffee_bag, roaster: create(:roaster, user: create(:user, :premium)), name: "New") }
  end

  test "suggests a starting grind from the most similar earlier bag per recent profile" do
    bag = create(:coffee_bag, roaster: @roaster, name: "Ethiopia", roast_level: "Light")
    stub = stub_typesafe(similar: {"coffee_0" => 0.1, "coffee_1" => 0.9}, relative_0: 2, relative_1: 1)

    bag.suggest_grind

    assert_requested(stub)
    assert_equal [
      {"profile" => "Adaptive", "grinder" => "EG-1", "setting" => "1.2", "based_on" => "Kenya", "relation" => "Slightly finer than"},
      {"profile" => "Blooming", "grinder" => "EG-1", "setting" => "2.0", "based_on" => "Brazil", "relation" => "Same as"}
    ], bag.reload.grind_suggestion
  end

  test "falls back to all-time top profiles when nothing was brewed in the past month" do
    Shot.update_all(start_time: 2.months.ago) # rubocop:disable Rails/SkipsModelValidations
    bag = create(:coffee_bag, roaster: @roaster, name: "Ethiopia")
    stub_typesafe(similar: {"coffee_0" => 0.9, "coffee_1" => 0.1}, relative_0: 2, relative_1: 2)

    bag.suggest_grind

    assert_equal %w[Adaptive Blooming], bag.reload.grind_suggestion.pluck("profile")
  end

  test "uses the bag's own latest shot once it has one" do
    create_shot(@kenya, "Adaptive", "1.3", start_time: 1.hour.ago, grind_suggestion: {"label" => "Finer", "setting_range" => %w[1.1 1.2]})
    stub_typesafe(relative_0: 2)

    @kenya.suggest_grind

    adaptive = @kenya.reload.grind_suggestion.find { it["profile"] == "Adaptive" }
    assert_equal({"profile" => "Adaptive", "grinder" => "EG-1", "setting" => "1.3", "label" => "Finer", "setting_range" => %w[1.1 1.2]}, adaptive)
  end

  private

  def create_shot(coffee_bag, profile_title, grinder_setting, enjoyment: nil, **attributes)
    create(:shot, user: @user, coffee_bag:, profile_title:, grinder_setting:, grinder_model: "EG-1", espresso_enjoyment: enjoyment, **attributes)
  end

  def stub_typesafe(similar: nil, **relatives)
    answers = relatives.transform_values { |level| {type: "score", probabilities: (0..4).to_h { [it.to_s, it == level ? 1.0 : 0.0] }} }
    answers[:similar] = {type: "choice", probabilities: similar} if similar
    stub_request(:post, TypeSafe::API_ENDPOINT).to_return(status: 200, body: {model: "jev-1.13.0", answers:}.to_json)
  end
end
