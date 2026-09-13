require "test_helper"
require "selenium-webdriver"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1440, 900 ]
end
