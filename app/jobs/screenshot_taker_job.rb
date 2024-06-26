require "aws-sdk-s3"

class ScreenshotTakerJob < ApplicationJob
  retry_on Timeout::Error, wait: :polynomially_longer

  queue_as :low

  def perform(shot)
    return if shot.screenshot?

    Timeout.timeout(10) do
      chart = ShotChart.new(shot)
      options = Oj.safe_load(File.read("lib/assets/chart_options.json"))
      options["xAxis"]["plotLines"] = chart.stages
      options["series"] = chart.shot_chart

      uri = URI.parse("https://export.highcharts.com/")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, {"Content-Type": "application/json"})
      request.body = {options:, type: "image/png"}.to_json
      response = http.request(request)
      File.write("tmp/screenshot-#{shot.id}.png", response.body, mode: "wb")

      client = Aws::S3::Client.new
      s3_response = client.put_object(
        acl: "public-read",
        body: File.read("tmp/screenshot-#{shot.id}.png"),
        bucket: "visualizer-coffee-shots",
        key: "screenshots/#{shot.id}.png"
      )
      shot.update(s3_etag: s3_response.etag) if s3_response&.etag
    end
  end
end
