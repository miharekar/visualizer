class CoffeeBagScraper
  BLOCK_PATTERNS = [
    /your access to this site has been limited/i,
    /access from your area has been temporarily limited/i
  ].freeze

  attr_reader :user, :url, :request_id

  def initialize(user, url, request_id)
    @user = user
    @url = url
    @request_id = request_id
  end

  def scrape
    run_step("fetching") { page_content(url) }
      .then { |content| run_step("extracting") { OpenAi.new.message(content) } }
      .then { |response| run_step("finalizing") { JSON.parse(response).compact_blank } }
  end

  private

  def run_step(status)
    CoffeeBagScraperChannel.broadcast_to(user, {request_id:, status:})
    yield
  end

  def page_content(url, limit = 5)
    raise ArgumentError, "Too many HTTP redirects" if limit.zero?

    response = Net::HTTP.get_response(URI(url))
    if is_blocked?(response)
      crawlbase_content(url)
    elsif response.is_a?(Net::HTTPRedirection)
      redirected_url = URI.join(url, response["location"]).to_s
      page_content(redirected_url, limit - 1)
    else
      content = extract_content(response)
      content.size < 100 ? crawlbase_content(url) : content
    end
  end

  def crawlbase_content(url)
    run_step("retrying") do
      response = SimpleDownloader.new("https://api.crawlbase.com/?token=#{Rails.application.credentials.crawlbase.token}&url=#{CGI.escape(url)}").response
      extract_content(response)
    end
  end

  def extract_content(response)
    if response.is_a?(Net::HTTPSuccess)
      doc = Nokogiri::HTML(response.body)
      doc.search("script, style, svg, img").remove
      doc.text.squish
    else
      raise "Failed to fetch page: #{response.code} #{response.message}"
    end
  end

  def is_blocked?(response)
    body = response.body.to_s
    BLOCK_PATTERNS.any? { |pattern| body.match?(pattern) }
  end
end
