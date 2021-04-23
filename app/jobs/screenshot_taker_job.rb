# frozen_string_literal: true

class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  rescue_from(ActiveJob::DeserializationError) do
    true
  end

  def perform(shot, force: false)
    shot.cloudinary_id = nil if force
    return if shot.cloudinary_id.present? || Rails.env.development?

    browser = Ferrum::Browser.new(window_size: [800, 500])
    browser.go_to("https://visualizer.coffee/shots/#{shot.id}/chart")
    browser.screenshot(path: "tmp/screenshot-#{shot.id}.png")
    browser.quit

    upload = Cloudinary::Uploader.upload("tmp/screenshot-#{shot.id}.png")
    shot.update(cloudinary_id: upload["public_id"])
  rescue Ferrum::TimeoutError, Ferrum::ProcessTimeoutError, ActiveStorage::IntegrityError
    Rails.logger.info("Something went wrong with Ferrum")
  end
end
