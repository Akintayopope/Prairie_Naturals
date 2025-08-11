# test/application_system_test_case.rb
# frozen_string_literal: true
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  # Devise (Warden) login for system tests
  include Warden::Test::Helpers
  setup    { Warden.test_mode! }
  teardown { Warden.test_reset! }
end
