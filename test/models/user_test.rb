require "test_helper"

class UserTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

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
