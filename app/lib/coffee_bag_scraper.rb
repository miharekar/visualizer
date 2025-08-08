class CoffeeBagScraper
  def get_info(url)
    scraped_content = page_content(url)
    response = OpenAi.new.message(scraped_content)
    JSON.parse(response).compact_blank
  rescue StandardError => e
    Appsignal.report_error(e)
    {error: e.message}
  end

  private

  def page_content(url, limit = 5)
    raise ArgumentError, "Too many HTTP redirects" if limit.zero?

    response = Net::HTTP.get_response(URI(url))
    case response
    when Net::HTTPSuccess
      doc = Nokogiri::HTML(response.body)
      doc.search("script, style, svg, img").remove
      doc.text.squish
    when Net::HTTPRedirection
      location = response["location"]
      page_content(location, limit - 1)
    else
      raise "Failed to fetch page: #{response.code} #{response.message}"
    end
  end
end
