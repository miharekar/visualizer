class SimpleDownloader
  prepend MemoWise

  attr_reader :uri, :request, :http

  def initialize(url)
    @uri = URI(url)
    @request = Net::HTTP::Get.new(uri)
    @http = Net::HTTP.new(uri.host, uri.port)
    @http.use_ssl = true
  end

  memo_wise def response
    http.request(request)
  end

  def body
    response.body if response.is_a?(Net::HTTPSuccess)
  end
end
