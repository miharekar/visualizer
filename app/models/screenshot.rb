# frozen_string_literal: true

class Screenshot
  attr_reader :shot_id

  def capture(shot_id)
    @path = Rails.root.join("public/screenshots/#{shot_id}.png")
    take_photo(shot_id)
  end

  private

  def take_photo(id)
    return if File.exist?(@path)

    setup_driver
    FileUtils.mkdir_p("public/screenshots/")
    @driver.navigate.to("http://localhost:3000/shots/#{id}/chart")
    @driver.manage.window.resize_to(767, 500)
    @driver.save_screenshot(@path)
    @driver.close
  end

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
