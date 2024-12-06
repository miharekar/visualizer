class CoffeeBagScraper
  def get_info(url)
    scraped_content = page_content(url)
    prompt = ERB.new(Rails.root.join("app/lib/templates/coffee_extraction_prompt.text.erb").read).result_with_hash(scraped_content:)
    response = Claude.new.message(prompt)
    JSON.parse(response["content"][0]["text"]).compact_blank
  rescue StandardError => e
    Appsignal.report_error(e)
    nil
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
