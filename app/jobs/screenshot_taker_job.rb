# frozen_string_literal: true

require "aws-sdk-s3"

class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do
    true
  end

  def perform(shot)
    return if shot.screenshot? || Rails.env.development? || Rails.env.test?

    chart = ShotChart.new(shot)
    options = JSON.parse(File.read("lib/assets/chart_options.json"))
    options["xAxis"]["plotLines"] = chart.stages
    options["series"] = chart.shot_chart

    uri = URI.parse("http://export.highcharts.com/")
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
