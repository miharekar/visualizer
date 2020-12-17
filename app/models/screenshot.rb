# frozen_string_literal: true

class Screenshot
  attr_reader :driver

  def capture
    setup
    take_photo
  end

  def setup
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
    @driver = Selenium::WebDriver.for :chrome, options: options
  end

  def tmp_file_path
    Rails.root.join("tmp", "screenshot-test.png")
  end

  def take_photo
    driver.navigate.to("http://localhost:3000/shots/cc5baa19-8476-4ab1-8aee-e4941a1e50fa/chart")
    driver.manage.window.resize_to(767, 500)
    driver.save_screenshot tmp_file_path
    driver.close
  end
end
