# config/initializers/stripe.rb
require "stripe"

secret_key = ENV["STRIPE_SECRET_KEY"].presence ||
             Rails.application.credentials.dig(:stripe, :secret_key)

publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"].presence ||
                  Rails.application.credentials.dig(:stripe, :publishable_key)

if secret_key.blank?
  msg = "Stripe secret key is missing. Set STRIPE_SECRET_KEY or credentials."
  Rails.env.production? ? raise(msg) : Rails.logger.warn("⚠️ #{msg}")
else
  Stripe.api_key = secret_key
  Rails.configuration.stripe = {
    secret_key:      secret_key,
    publishable_key: publishable_key
  }
end
