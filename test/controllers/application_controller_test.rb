require "test_helper"

class ApplicationControllerTest < ActiveSupport::TestCase
  test "journal is shared with views but scoped to one controller instance" do
    first = build(:user)
    Current.session = Session.new(user: first)
    controller = ApplicationController.new
    journal = controller.__send__(:journal)
    assert_same journal, controller.__send__(:journal)
    assert_same journal, controller.view_context.journal
    assert_same first, journal.user
    Current.reset
    second = build(:user)
    Current.session = Session.new(user: second)
    other_journal = ApplicationController.new.__send__(:journal)
    assert_not_same journal, other_journal
    assert_same second, other_journal.user
  ensure
    Current.reset
  end
end
