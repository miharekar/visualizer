class CoffeeBagScraper
  def get_info(url)
    html = fetch_page(url)
    prompt = ERB.new(Rails.root.join("app/lib/templates/coffee_extraction_prompt.text.erb").read).result_with_hash(html:)
    response = Claude.new.message(prompt)
    JSON.parse(response["content"][0]["text"]).compact_blank
  rescue StandardError => e
    Appsignal.report_error(e)
    nil
  end

  private

  def fetch_page(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == "https"
    response = http.get(uri.request_uri)
    raise "Failed to fetch page: #{response.code} #{response.message}" unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::HTML(response.body)
    doc.search("script, style").remove
    doc.to_html
  end
end
