require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "enabling rich text promotes legacy notes on their next save" do
    user = create(:user, rich_text_enabled: false)
    shot = create(:shot, user:)
    shot.update_columns(bean_notes: "**Chocolate**") # rubocop:disable Rails/SkipsModelValidations

    user.update!(rich_text_enabled: true)

    assert_equal "**Chocolate**", shot.reload[:bean_notes]
    assert_includes shot.note_html(:bean_notes), "<strong>Chocolate</strong>"
    assert_not shot.bean_notes.body.present?

    shot.update!(profile_title: "Saved")

    assert_equal "Chocolate", shot.reload[:bean_notes]
    assert_includes shot.bean_notes.to_s, "<strong>Chocolate</strong>"
  end

  test "rich text cannot be disabled after conversion" do
    user = create(:user)

    assert_not user.update(rich_text_enabled: false)
    assert_includes user.errors[:rich_text_enabled], "cannot be disabled after notes have been converted"
  end

  test "it can generate an unsubscribe token for a notification" do
    user = create(:user)

    test_token = user.unsubscribe_token_for("test")
    other_token = user.unsubscribe_token_for("other")

    assert_not_nil test_token
    assert_not_nil other_token
    assert_not_equal test_token, other_token

    token_definition = User.token_definitions[:unsubscribe]

    test_data = token_definition.message_verifier.verify(test_token, purpose: token_definition.full_purpose)
    assert_equal user.id, test_data["id"]
    assert_equal "test", test_data["notification"]

    other_data = token_definition.message_verifier.verify(other_token, purpose: token_definition.full_purpose)
    assert_equal user.id, other_data["id"]
    assert_equal "other", other_data["notification"]
  end

  test "it can unsubscribe from a notification by token" do
    user = create(:user)
    token = user.unsubscribe_token_for("test")

    assert user.reload.notify?("test")
    assert_equal %w[shot_uploaded], user.reload.unsubscribed_from

    User.unsubscribe_by_token!(token)
    assert_not user.reload.notify?("test")
    assert_equal %w[shot_uploaded test], user.reload.unsubscribed_from

    user = create(:user)
    user.update(unsubscribed_from: %w[something test])
    assert_equal %w[something test], user.reload.unsubscribed_from
    User.unsubscribe_by_token!(user.unsubscribe_token_for("test"))
    assert_equal %w[something test], user.reload.unsubscribed_from

    User.unsubscribe_by_token!("shouldn't raise")
  end

  test "shot uploaded email notifications are opt in" do
    user = create(:user)

    assert_not user.notify?(:shot_uploaded)
    assert_includes user.unsubscribed_from, "shot_uploaded"

    user.update!(unsubscribed_from: [])

    assert user.notify?(:shot_uploaded)
  end

  test "coffee_bag_metadata_fields defaults to empty list" do
    user = create(:user)

    assert_equal [], user.coffee_bag_metadata_fields
  end

  test "unified_chart follows the user preference" do
    user = build(:user)
    assert_not user.unified_chart?

    user = build(:user, unified_chart: true)
    assert user.unified_chart?
  end
end
