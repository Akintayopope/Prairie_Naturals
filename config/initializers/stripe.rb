# config/initializers/stripe.rb

# config/initializers/stripe.rb
Stripe.api_key = ENV["STRIPE_SECRET_KEY"]

Rails.configuration.stripe = {
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
  secret_key:      ENV["STRIPE_SECRET_KEY"]
}

if Stripe.api_key.to_s.strip.empty?
  Rails.logger.warn "[Stripe] Missing STRIPE_SECRET_KEY env var"
end
