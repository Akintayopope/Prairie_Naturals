# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'

# Load the Rails app
require File.expand_path('../config/environment', __dir__)

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if defined?(Rails) && Rails.env.production?

# RSpec + Rails
require 'rspec/rails'

# Load files in spec/support
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# If you use ActiveRecord, maintain the test schema
begin
  if defined?(ActiveRecord::Migration)
    ActiveRecord::Migration.maintain_test_schema!
  end
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # If using ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures" if config.respond_to?(:fixture_path=)

  # Use transactions for non-JS tests (fast)
  if config.respond_to?(:use_transactional_fixtures=)
    config.use_transactional_fixtures = true
  end

  # Infer spec type (model, request, system, etc.) from location
  config.infer_spec_type_from_file_location!

  # Filter gem backtraces
  config.filter_rails_from_backtrace!
end
