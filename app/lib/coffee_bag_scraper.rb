class CoffeeBagScraper
  class FetchBlockedError < StandardError; end

  BLOCK_PATTERNS = {
    /wordfence/i => "This site blocked automated access from the server.",
    /your access to this site has been limited/i => "This site blocked automated access from the server.",
    /access from your area has been temporarily limited/i => "This site blocked automated access from the server.",
    /attention required/i => "This site is showing a bot protection challenge.",
    /cloudflare/i => "This site is showing a bot protection challenge.",
    /captcha/i => "This site requires a captcha before it can be viewed automatically."
  }.freeze

  def get_info(url)
    scraped_content = page_content(url)
    response = OpenAi.new.message(scraped_content)
    JSON.parse(response).compact_blank
  rescue FetchBlockedError => e
    {error: e.message}
  rescue StandardError => e
    Appsignal.report_error(e)
    {error: e.message}
  end

  private

  def page_content(url, limit = 5)
    raise ArgumentError, "Too many HTTP redirects" if limit.zero?

    response = Net::HTTP.get_response(URI(url))
    blocked = is_blocked?(response)
    raise FetchBlockedError, blocked if blocked

    case response
    when Net::HTTPSuccess
      doc = Nokogiri::HTML(response.body)
      doc.search("script, style, svg, img").remove
      doc.text.squish
    when Net::HTTPRedirection
      page_content(response["location"], limit - 1)
    else
      raise "Failed to fetch page: #{response.code} #{response.message}"
    end
  end

  def fetch_response(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 5, read_timeout: 10) do |http|
      request = Net::HTTP::Get.new(uri)
      request["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
      request["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
      request["Accept-Language"] = "en-US,en;q=0.9"
      http.request(request)
    end
  end

  def is_blocked?(response)
    blocked_match = BLOCK_PATTERNS.find { |pattern, _message| response.body.to_s.match?(pattern) }
    return blocked_match.last if blocked_match
    return unless response.is_a?(Net::HTTPServiceUnavailable)

    "This site is temporarily unavailable."
  end
end
