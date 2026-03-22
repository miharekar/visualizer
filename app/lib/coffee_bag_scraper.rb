class CoffeeBagScraper
  BLOCK_PATTERNS = [
    /your access to this site has been limited/i,
    /access from your area has been temporarily limited/i
  ].freeze

  def get_info(url)
    scraped_content = page_content(url)
    response = OpenAi.new.message(scraped_content)
    JSON.parse(response).compact_blank
  rescue StandardError => e
    Appsignal.report_error(e)
    {error: e.message}
  end

  private

  def page_content(url, limit = 5, via_crawlbase: false)
    raise ArgumentError, "Too many HTTP redirects" if limit.zero?

    response = via_crawlbase ? content_via_crawlbase(url) : Net::HTTP.get_response(URI(url))
    return page_content(url, 1, via_crawlbase: true) if is_blocked?(response) && !via_crawlbase

    case response
    when Net::HTTPSuccess
      doc = Nokogiri::HTML(response.body)
      doc.search("script, style, svg, img").remove
      content = doc.text.squish
      return page_content(url, 1, via_crawlbase: true) if content.size < 100 && !via_crawlbase

      content
    when Net::HTTPRedirection
      redirected_url = URI.join(url, response["location"]).to_s
      page_content(redirected_url, limit - 1)
    else
      raise "Failed to fetch page: #{response.code} #{response.message}"
    end
  end

  def content_via_crawlbase(url)
    SimpleDownloader.new("https://api.crawlbase.com/?token=#{Rails.application.credentials.crawlbase.token}&url=#{CGI.escape(url)}").response
  end

  def is_blocked?(response)
    body = response.body.to_s
    BLOCK_PATTERNS.any? { |pattern| body.match?(pattern) }
  end
end
