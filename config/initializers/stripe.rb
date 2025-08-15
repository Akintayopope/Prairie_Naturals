# config/initializers/stripe.rb

# Read keys from environment
stripe_secret     = ENV["STRIPE_SECRET_KEY"].to_s
stripe_publishable = ENV["STRIPE_PUBLISHABLE_KEY"].to_s

if stripe_secret.empty? || stripe_publishable.empty?
  Rails.logger.warn("⚠️ Stripe keys are missing — Stripe API is disabled.")
else
  require "stripe"
  Stripe.api_key = stripe_secret
  Rails.configuration.stripe = {
    publishable_key: stripe_publishable,
    secret_key:      stripe_secret
  }
end
