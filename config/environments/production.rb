Rails.application.configure do
  # --- standard production settings above ---

  # Use Supabase for Active Storage in production
  config.active_storage.service = :supabase

  # Use libvips for fast, memory-efficient variants (install libvips in your Dockerfile)
  config.active_storage.variant_processor = :vips

  # Keep integrity checks ON (default). If you’re still diagnosing byte mismatches,
  # you can temporarily flip this to false, but turn it back on afterwards.
  # config.active_storage.verify_integrity_in_download = false

  # If you serve images directly from Supabase public URLs, no asset host needed.
  # If you reverse-proxy or CDN them, you can set:
  # config.asset_host = "https://your-cdn.example.com"

  # Content Security Policy: allow Supabase images (and data/blob for ActiveStorage previews)
  # If you manage CSP via this block, include:
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.img_src     :self, :https, :data, :blob, "*.supabase.co"
    policy.font_src    :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https
  end

  # Rails 8 uses Solid Queue by default for Active Job.
  # Make sure you ran:
  #   bin/rails solid_queue:install:migrations
  #   RAILS_ENV=production bin/rails db:migrate
  # And run a worker process in production:
  #   bundle exec rake solid_queue:start
end
