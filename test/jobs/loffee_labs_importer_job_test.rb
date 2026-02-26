require "test_helper"

class LoffeeLabsImporterJobTest < ActiveJob::TestCase
  setup do
    @roasters_url = "https://example.com/roasters.csv"
    @api_key = "test-api-key"
    @beans_url = "https://www.loffeelabs.com/wp-json/beanbase/v1/beans?api_key=#{@api_key}"
  end

  test "skips beans coming from excluded source urls" do
    roaster = CanonicalRoaster.create!(name: "DAK", loffee_labs_id: "DAK")
    coffee_bag = CanonicalCoffeeBag.create!(
      canonical_roaster: roaster,
      loffee_labs_id: "25769",
      name: "Milky Cake"
    )

    downloader_responses = [
      Struct.new(:body).new("roaster,link,country,locality\nDAK,https://dak.coffee,Netherlands,Amsterdam\n"),
      Struct.new(:body).new(
        {
          data: [
            {
              "id" => "25769",
              "date" => "2026-01-01",
              "roaster" => "DAK",
              "roast-name" => "DAK - Milky Cake - Cauca, Colombia - 250g",
              "link" => "https://airworkscoffee.com/products/dak-milky-cake-cauca-colombia-250g"
            }
          ]
        }.to_json
      )
    ]
    downloader_new = ->(_url) { downloader_responses.shift }
    original_new = SimpleDownloader.method(:new)
    SimpleDownloader.define_singleton_method(:new, downloader_new)

    assert_no_changes(-> { coffee_bag.reload.name }) do
      begin
        LoffeeLabsImporterJob.perform_now(cut_off: Date.new(2025, 1, 1))
      ensure
        SimpleDownloader.define_singleton_method(:new, original_new)
      end
    end

    assert_empty downloader_responses
  end
end
