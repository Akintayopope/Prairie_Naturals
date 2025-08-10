
# # config/initializers/stripe.rb
Stripe.api_key = ENV.fetch("STRIPE_SECRET_KEY") # do not hardcode
Rails.configuration.stripe = {
  publishable_key: ENV["STRIPE_PUBLISHABLE_KEY"],
  secret_key:      ENV["STRIPE_SECRET_KEY"]
}
