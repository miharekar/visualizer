require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "journal is scoped to the current request and resets with it" do
    first = build(:user)
    Current.session = Session.new(user: first)
    journal = Current.journal
    assert_same journal, Current.journal
    assert_same first, journal.user
    Current.reset
    assert_nil Current.journal
    second = build(:user)
    Current.session = Session.new(user: second)
    assert_not_same journal, Current.journal
    assert_same second, Current.journal.user
  ensure
    Current.reset
  end
end
