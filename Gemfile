source "https://rubygems.org"

ruby File.read(".ruby-version").strip rescue nil

gem "rails", "~> 8.0.2"
gem "propshaft"

# DB / server
gem "pg", "~> 1.5"                 # 1.1 is too old; use >=1.5 on Rails 8
gem "puma", ">= 5.0"

# Hotwire / JS
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"

# Views / JSON
gem "jbuilder"

# Platform bits
gem "tzinfo-data", platforms: %i[windows jruby]

# Rails 8 “Solid” adapters
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Boot speed
gem "bootsnap", require: false

# Deploy tools
gem "kamal", require: false
gem "thruster", require: false

# Images (Active Storage variants)
gem "image_processing", "~> 1.2"

# Auth / admin / payments / pagination
gem "devise"
gem "activeadmin"
gem "stripe"
gem "kaminari"
gem "friendly_id", "~> 5.4.0"

# Front-end
gem "bootstrap", "~> 5.3.0"
gem "sassc-rails"

# XML/HTML, PDFs
gem "nokogiri", "~> 1.16"          # "~> 1.18" doesn’t exist; 1.16.x is current/stable
gem "prawn"
gem "prawn-table"

# Env
gem "dotenv-rails"

# Charts & helpers
gem "chartkick", "~> 5.2"
gem "groupdate", "~> 6.7"
# Consider using npm-based Chart.js instead of the old gem:
# gem "chart-js-rails"  # <- remove if you load Chart.js via importmap/npm
gem "httparty"

# Discord bot/webhook (pure-Ruby)
gem "discordrb", "~> 3.5"

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end

gem 'sidekiq'

gem "cloudinary"
gem "activestorage-cloudinary-service"