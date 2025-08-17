# config/initializers/stripe.rb
require "stripe"

# Skip Stripe entirely if disabled
if defined?(DISABLE_STRIPE) && DISABLE_STRIPE
  STRIPE_ENABLED = false
  Rails.configuration.stripe = { secret_key: nil, publishable_key: nil, webhook_secret: nil }
  Rails.logger.warn("[stripe] disabled (SAFE_MODE / DISABLE_STRIPE).")
  return
end

# In production, rely on ENV only (avoid credentials surprises)
secret_key = if Rails.env.production?
               ENV["STRIPE_SECRET_KEY"].presence
             else
               ENV["STRIPE_SECRET_KEY"].presence ||
               Rails.application.credentials.dig(:stripe, :secret_key)
             end

publishable_key = if Rails.env.production?
                     ENV["STRIPE_PUBLISHABLE_KEY"].presence
                   else
                     ENV["STRIPE_PUBLISHABLE_KEY"].presence ||
                     Rails.application.credentials.dig(:stripe, :publishable_key)
                   end

STRIPE_ENABLED = secret_key.present?

Rails.configuration.stripe = {
  secret_key:      secret_key,
  publishable_key: publishable_key,
  webhook_secret:  ENV["STRIPE_WEBHOOK_SECRET"]
}

if STRIPE_ENABLED
  Stripe.api_key = secret_key
  Rails.logger.info("[stripe] configured.")
else
  Rails.logger.warn("⚠️ [stripe] keys missing — Stripe disabled.")
end
