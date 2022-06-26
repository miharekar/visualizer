# frozen_string_literal: true

require "aws-sdk-s3"

class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  def perform(from: 1.hour.ago)
    return if Rails.env.development?

    browser = Ferrum::Browser.new(window_size: [800, 500])
    client = Aws::S3::Client.new
    Shot.where(created_at: from..).where(s3_etag: nil).find_each do |shot|
      next if shot.screenshot?

      browser.go_to("https://visualizer.coffee/shots/#{shot.id}/chart")
      browser.screenshot(path: "tmp/screenshot-#{shot.id}.png")
      response = client.put_object(
        acl: "public-read",
        body: File.read("tmp/screenshot-#{shot.id}.png"),
        bucket: "visualizer-coffee-shots",
        key: "screenshots/#{shot.id}.png"
      )
      shot.update(s3_etag: response.etag) if response&.etag
    end
    browser.quit
  rescue Ferrum::TimeoutError, Ferrum::ProcessTimeoutError
    Rails.logger.info("Something went wrong with Ferrum")
  end
end
