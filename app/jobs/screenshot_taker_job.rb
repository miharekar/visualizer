class ScreenshotTakerJob < ApplicationJob
  queue_as :default

  def perform(shot)
    return if File.exist?(shot.screenshot_path)

    setup_driver
    FileUtils.mkdir_p("public/screenshots/")
    @driver.navigate.to("https://visualizer.coffee/shots/#{shot.id}/chart")
    @driver.manage.window.resize_to(767, 500)
    @driver.save_screenshot(shot.screenshot_path)
    @driver.close
  end

  private

  def setup_driver
    chrome_shim = ENV.fetch("GOOGLE_CHROME_SHIM", nil)
    chrome_bin = ENV.fetch("GOOGLE_CHROME_BIN", nil)

    Selenium::WebDriver::Chrome.path = chrome_bin if chrome_bin
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless")
    options.add_argument("--hide-scrollbars")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-gpu")
    options.add_argument("--disable-dev-shm-usage")
    options.binary = chrome_shim if chrome_shim

    @driver = Selenium::WebDriver.for(:chrome, options: options)
  end
end
