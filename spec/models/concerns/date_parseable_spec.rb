require 'rails_helper'

RSpec.describe DateParseable do
  let(:dummy_class) { Class.new { include DateParseable } }
  let(:dummy_instance) { dummy_class.new }

  User::DATE_FORMATS.each do |format_name, format_string|
    context "with #{format_name} format" do
      it "parses the date correctly" do
        date = case format_name
        when "dd.mm.yyyy" then "09.08.2023"
        when "mm.dd.yyyy" then "08.09.2023"
        when "yyyy.mm.dd" then "2023.08.09"
        end

        expect(dummy_instance.parse_date(date, format_string)).to eq Date.new(2023, 08, 09)
      end
    end
  end

  it "returns nil for nil input" do
    expect(dummy_instance.parse_date(nil, "%d.%m.%Y")).to be_nil
  end

  it "returns nil for empty string input" do
    expect(dummy_instance.parse_date("", "%d.%m.%Y")).to be_nil
  end

  it "parses ISO 8601 format" do
    expect(dummy_instance.parse_date("2023-08-09", "%d.%m.%Y")).to eq Date.new(2023, 08, 09)
  end

  it "parses other common formats" do
    expect(dummy_instance.parse_date("Dec 09, 2023", "%d.%m.%Y")).to eq Date.new(2023, 08, 09)
  end

  it "returns nil for invalid date strings" do
    expect(dummy_instance.parse_date("not a date", "%d.%m.%Y")).to be_nil
  end
end
