# Be explicit so cookies behave predictably in dev and prod.
Rails.application.config.session_store :cookie_store,
  key: "_prairie_naturals_session",
  secure: Rails.env.production?,  # false in dev, true in prod
  same_site: :lax                 # good for normal form posts
# Do NOT set :domain unless you truly need cross-subdomain cookies.
