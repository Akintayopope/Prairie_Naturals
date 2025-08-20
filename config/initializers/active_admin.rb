ActiveAdmin.setup do |config|
  config.site_title = "Prairie Naturals"
  config.register_stylesheet "active_admin_overrides.css"

  config.default_namespace = :internal

  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_admin_user

  config.logout_link_path = :destroy_admin_user_session_path

  config.comments = false
  config.filter_attributes = %i[
    encrypted_password
    password
    password_confirmation
  ]
  config.localize_format = :long
  config.batch_actions = true
end
