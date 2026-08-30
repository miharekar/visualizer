require "test_helper"

class CoffeeBagScraperTest < ActiveSupport::TestCase
  test "identifies multicast addresses" do
    assert IPAddr.new("224.0.0.1").multicast?
    assert IPAddr.new("ff00::1").multicast?
    assert_not IPAddr.new("8.8.8.8").multicast?
  end

  test "rejects private addresses" do
    scraper = CoffeeBagScraper.new(create(:user), "http://127.0.0.1", "request-id")

    error = assert_raises(ArgumentError) { scraper.__send__(:page_content, "http://127.0.0.1") }

    assert_equal "URL must resolve to a public IP address", error.message
  end

  test "rejects redirects to private addresses" do
    scraper = CoffeeBagScraper.new(create(:user), "https://93.184.216.34", "request-id")
    stub_request(:get, "https://93.184.216.34/").to_return(status: 302, headers: {"Location" => "http://127.0.0.1/secret"})

    assert_raises(ArgumentError) { scraper.__send__(:page_content, "https://93.184.216.34") }
  end
end
