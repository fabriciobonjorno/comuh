# frozen_string_literal: true

require "capybara/rspec"
require "selenium/webdriver"

Capybara.default_max_wait_time = 5
Capybara.server = :puma
Capybara.server_host = "127.0.0.1"

%w[
  /usr/bin/google-chrome-stable
  /usr/bin/google-chrome
  /usr/bin/chromium-browser
  /usr/bin/chromium
].each do |path|
  break unless ENV["CHROME_BIN"].blank?
  ENV["CHROME_BIN"] = path if File.exist?(path)
end

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 900 ] do |options|
      options.add_argument("--headless=new")
      options.add_argument("--no-sandbox")
      options.add_argument("--disable-dev-shm-usage")
      options.add_argument("--disable-gpu")
      options.add_argument("--window-size=1400,900")
      options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
    end
  end
end
