# config/initializers/stripe.rb
require "stripe"

if Rails.env.production?
  # strict in prod: fail if missing
  Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY")
else
  # dev/test/CI: allow a dummy fallback so boot never crashes
  Stripe.api_key = ENV["STRIPE_SECRET_KEY"] || "sk_test_dummy_123"
end

Rails.configuration.stripe = {
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"] || "pk_test_dummy_123",
  secret_key:      Stripe.api_key
}
