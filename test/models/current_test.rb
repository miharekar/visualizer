require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  teardown do
    Current.reset
  end

  test "set_timezone_from_cookie handles invalid utf8" do
    invalid = "\xC3\x28".dup.force_encoding("UTF-8")

    Current.set_timezone_from_cookie(invalid)

    assert_equal "UTC", Current.timezone.name
  end

  test "set_timezone_from_cookie uses valid cookie" do
    Current.set_timezone_from_cookie("Europe/Ljubljana")

    assert_equal "Europe/Ljubljana", Current.timezone.name
  end
end
