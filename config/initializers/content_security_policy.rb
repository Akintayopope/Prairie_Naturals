# Be sure to restart your server when you modify this file.
# See: https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.config.content_security_policy do |policy|
  # Baseline
  policy.default_src :self
  policy.base_uri    :self

  # Images — allow data/blob and Cloudinary
  policy.img_src     :self, :https, :data, :blob, "res.cloudinary.com"

  # Fonts / Styles (keep :unsafe_inline only if you actually use inline styles)
  policy.font_src    :self, :https, :data
  policy.style_src   :self, :https, :unsafe_inline

  # Scripts (add :unsafe_inline if needed; prefer using nonces instead)
  policy.script_src  :self, :https

  # XHR/WebSocket
  policy.connect_src :self, :https


  # Media (videos, etc.)
  policy.media_src   :self, :https, :data, :blob

  # Frames (Stripe Checkout, etc.) — add hosts as needed
  policy.frame_src   :self, :https
end

# Generate nonces for inline tags (works with importmap/inline)
Rails.application.config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
Rails.application.config.content_security_policy_nonce_directives = %w(script-src style-src)

# Enforce (set to true for report-only while testing)
Rails.application.config.content_security_policy_report_only = false
