# config/initializers/stripe.rb
require "stripe"

secret_key = ENV["STRIPE_SECRET_KEY"].presence ||
             Rails.application.credentials.dig(:stripe, :secret_key)

publishable_key = ENV["STRIPE_PUBLISHABLE_KEY"].presence ||
                  Rails.application.credentials.dig(:stripe, :publishable_key)

STRIPE_ENABLED = secret_key.present?

Rails.configuration.stripe = {
  secret_key:      secret_key,
  publishable_key: publishable_key,
  webhook_secret:  ENV["STRIPE_WEBHOOK_SECRET"] # fine to be nil for now
}

if STRIPE_ENABLED
  Stripe.api_key = secret_key
  Rails.logger.info("[stripe] Secret key present — Stripe client configured.")
else
  Rails.logger.warn("⚠️ Stripe keys are missing — Stripe API is disabled.")
end
