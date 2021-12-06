# frozen_string_literal: true

require "aws-sdk-s3"

class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do
    true
  end

  def perform(shot)
    return if shot.screenshot? || Rails.env.development?

    browser = Ferrum::Browser.new(window_size: [800, 500])
    browser.go_to("https://visualizer.coffee/shots/#{shot.id}/chart")
    browser.screenshot(path: "tmp/screenshot-#{shot.id}.png")
    browser.quit

    client = Aws::S3::Client.new
    response = client.put_object(
      acl: "public-read",
      body: File.read("tmp/screenshot-#{shot.id}.png"),
      bucket: "visualizer-coffee-shots",
      key: "screenshots/#{shot.id}.png"
    )
    shot.update(s3_etag: response.etag) if response&.etag
  rescue Ferrum::TimeoutError, Ferrum::ProcessTimeoutError
    Rails.logger.info("Something went wrong with Ferrum")
  end
end
