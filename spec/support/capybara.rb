require 'capybara/rspec'

RSpec.configure do |config|
  # Fast: no browser for non-JS pages
  config.before(:each, type: :system) do
    driven_by :rack_test
  end
  # Only if you tag an example with `js: true`
  config.before(:each, type: :system, js: true) do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
  end
end
