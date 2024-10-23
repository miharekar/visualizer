require "test_helper"

class DateParseableTest < ActiveSupport::TestCase
  setup do
    @dummy_class = Class.new { include DateParseable }
    @dummy_instance = @dummy_class.new
  end

  User::DATE_FORMATS.each do |format_name, format_string|
    test "parses the date correctly with #{format_name} format" do
      date = case format_name
      when "dd.mm.yyyy" then "09.08.2023"
      when "mm.dd.yyyy" then "08.09.2023"
      when "yyyy.mm.dd" then "2023.08.09"
      end

      assert_equal Date.new(2023, 8, 9), @dummy_instance.parse_date(date, format_string)
    end
  end

  test "returns nil for nil input" do
    assert_nil @dummy_instance.parse_date(nil, "%d.%m.%Y")
  end

  test "returns nil for empty string input" do
    assert_nil @dummy_instance.parse_date("", "%d.%m.%Y")
  end

  test "parses ISO 8601 format" do
    assert_equal Date.new(2023, 8, 9), @dummy_instance.parse_date("2023-08-09", "%d.%m.%Y")
  end

  test "parses other common formats" do
    assert_equal Date.new(2023, 12, 9), @dummy_instance.parse_date("Dec 09, 2023", "%d.%m.%Y")
  end

  test "returns nil for invalid date strings" do
    assert_nil @dummy_instance.parse_date("not a date", "%d.%m.%Y")
  end

  test "parses date correctly regardless of user's date format" do
    date = "2024-03-11"
    expected_date = Date.new(2024, 3, 11)

    assert_equal expected_date, @dummy_instance.parse_date(date, "%d.%m.%Y")
  end
end
