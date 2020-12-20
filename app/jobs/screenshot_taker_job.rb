# frozen_string_literal: true

class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do |_e|
    true
  end

  def perform(shot, force: false)
    shot.cloudinary_id = false if force
    return if shot.cloudinary_id.present?

    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--hide-scrollbars")
    driver = Selenium::WebDriver.for(:chrome, options: options)
    driver.navigate.to("https://visualizer.coffee/shots/#{shot.id}/chart")
    driver.manage.window.resize_to(767, 500)
    driver.save_screenshot("tmp/screenshot-#{shot.id}.png")
    driver.quit

    upload = Cloudinary::Uploader.upload("tmp/screenshot-#{shot.id}.png")
    shot.update(cloudinary_id: upload["public_id"])
  rescue StandardError
    Rails.logger.info("Something went wrong")
  end
end
