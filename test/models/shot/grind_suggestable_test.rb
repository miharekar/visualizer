require "test_helper"

class Shot::GrindSuggestableTest < ActiveSupport::TestCase
  setup do
    @user = create(:user, :admin)
  end

  test "enqueues suggestion for new admin shots with a duration" do
    assert_enqueued_with(job: GrindSuggestionJob) { create_shot(duration: 30) }
  end

  test "skips non-admin users and shots without duration" do
    assert_no_enqueued_jobs(only: GrindSuggestionJob) do
      create(:shot, user: create(:user, :premium), duration: 30)
      create_shot(duration: nil)
    end
  end

  test "re-suggests only when dial-in attributes change" do
    shot = create_shot(duration: 30)
    assert_no_enqueued_jobs(only: GrindSuggestionJob) { shot.update!(barista: "Someone") }
    assert_enqueued_with(job: GrindSuggestionJob) { shot.update!(grinder_setting: "15") }
    assert_enqueued_with(job: GrindSuggestionJob) { Shot.find(shot.id).update!(espresso_notes: "Sour and thin") }
  end

  test "suggests an exact range from same coffee, profile and grinder history" do
    create_shot(grinder_setting: "12", duration: 30, espresso_enjoyment: 60, start_time: 3.days.ago)
    create_shot(grinder_setting: "14", duration: 25, espresso_enjoyment: 85, start_time: 2.days.ago)
    create_shot(grinder_setting: "16", duration: 20, espresso_enjoyment: 50, start_time: 1.day.ago)
    shot = create_shot(grinder_setting: "18", duration: 15, espresso_enjoyment: 40)
    stub = stub_typesafe(1 => 0.8, 2 => 0.15, 3 => 0.05)

    shot.suggest_grind_now

    assert_requested(stub)
    suggestion = shot.reload.grind_suggestion
    assert_equal "finer", suggestion["direction"]
    assert_equal "Finer", suggestion["label"]
    assert_equal %w[13 15], suggestion["setting_range"]
  end

  test "suggests an exact range from typical time when shots have no enjoyment" do
    create_shot(grinder_setting: "12", duration: 30, start_time: 3.days.ago)
    create_shot(grinder_setting: "14", duration: 25, start_time: 2.days.ago)
    create_shot(grinder_setting: "16", duration: 20, start_time: 1.day.ago)
    shot = create_shot(grinder_setting: "18", duration: 15)
    stub_typesafe(1 => 0.8, 2 => 0.2)

    shot.suggest_grind_now

    assert_equal %w[13 15], shot.reload.grind_suggestion["setting_range"]
  end

  test "suggests words for shots without a coffee" do
    shot = create_shot(bean_brand: nil, bean_type: nil, grinder_setting: "18", duration: 15)
    stub_typesafe(1 => 0.9, 2 => 0.1)

    shot.suggest_grind_now

    assert_equal "Finer", shot.reload.grind_suggestion["label"]
  end

  test "falls back to words when history disagrees with the direction" do
    create_shot(grinder_setting: "12", duration: 30, espresso_enjoyment: 60, start_time: 3.days.ago)
    create_shot(grinder_setting: "14", duration: 25, espresso_enjoyment: 85, start_time: 2.days.ago)
    shot = create_shot(grinder_setting: "18", duration: 15, espresso_enjoyment: 40)
    stub_typesafe(5 => 0.9, 4 => 0.1)

    shot.suggest_grind_now

    suggestion = shot.reload.grind_suggestion
    assert_equal "coarser", suggestion["direction"]
    assert_nil suggestion["setting_range"]
  end

  test "is not sure when direction probability is split" do
    shot = create_shot(grinder_setting: "18", duration: 15)
    stub_typesafe(1 => 0.4, 3 => 0.2, 5 => 0.4)

    shot.suggest_grind_now

    suggestion = shot.reload.grind_suggestion
    assert_equal "Not sure", suggestion["label"]
    assert_nil suggestion["direction"]
  end

  test "journal shows grind suggestion column to admins only" do
    shot = create_shot(grind_suggestion: {"label" => "Coarser", "setting_range" => %w[3.1 4.3]})
    journal = Journal.new(@user)

    assert_equal "Coarser → 3.1–4.3", journal.value(shot, "grind_suggestion")
    assert_not journal.editable_columns.key?("grind_suggestion")
    assert_not Journal.new(create(:user, :premium)).columns.key?("grind_suggestion")
  end

  private

  def create_shot(**attributes)
    create(:shot, user: @user, bean_brand: "Roaster", bean_type: "Ethiopia", profile_title: "Adaptive", grinder_model: "Niche", **attributes)
  end

  def stub_typesafe(probabilities)
    probabilities = (0..6).to_h { [it.to_s, probabilities.fetch(it, 0.0)] }
    body = {model: "jev-1.13.0", answers: {adjustment: {type: "score", probabilities:}, puck_issue: {type: "noul", noul: 0.1}}}
    stub_request(:post, TypeSafe::API_ENDPOINT).to_return(status: 200, body: body.to_json)
  end
end
