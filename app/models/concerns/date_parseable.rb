module DateParseable
  def parse_date(input, date_format_string)
    date_string = input.to_s
    begin
      Date.strptime(date_string, date_format_string)
    rescue Date::Error
      Date.parse(date_string)
    end
  rescue Date::Error
    nil
  end
end
