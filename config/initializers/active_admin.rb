# config/initializers/active_admin.rb
ActiveAdmin.setup do |config|
  # ==== Branding ====
  config.site_title = "Prairie Naturals"
   config.register_stylesheet 'active_admin_overrides.css'
  # ==== Namespace / URL ====
  # Put the entire admin under /internal instead of /admin
  # (security-by-obscurity helper; auth still required).
  config.default_namespace = :internal

  # ==== AuthN / AuthZ ====
  # Use Devise's admin scope. These are the correct methods for AdminUser.
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method   = :current_admin_user

  # Logout is a DELETE by default; keep it explicit.
  config.logout_link_path   = :destroy_admin_user_session_path
  # config.logout_link_method = :delete  # <- default; uncomment if you prefer to be explicit

  # If you later plug Pundit/CanCan, set the adapter here.
  # config.authorization_adapter = ActiveAdmin::PunditAdapter
  # config.on_unauthorized_access = :access_denied  # define this in ApplicationController if you enable it

  # ==== General UX / safety ====
  config.comments = false                             # disable AA comments unless you actively use them
  config.filter_attributes = [:encrypted_password, :password, :password_confirmation]
  config.localize_format = :long
  config.batch_actions = true

  # Optional: hide logged-out AA pages (login) from search engines
  # config.meta_tags_for_logged_out_pages = { robots: "noindex,nofollow" }

  # If you use Webpacker for AA assets (usually no):
  # config.use_webpacker = true
end
