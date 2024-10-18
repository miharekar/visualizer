module DateParseable
  def parse_date(date_string, date_format_string)
    if date_string&.match?(/^\d{2,4}[\.\-\/]\d{2}[\.\-\/]\d{2,4}$/)
      Date.strptime(date_string, date_format_string)
    else
      Date.parse(date_string)
    end
  rescue
    nil
  end
end
