class ApplicationController < ActionController::Base
  before_action :authenticate_user!  # Devise helper: require login for all pages
  before_action :require_modern_browser

  private

  # ✅ Optional: Modern browser check (customize if using a gem like `browser`)
  def require_modern_browser
    # Example (only if you're using the `browser` gem):
    # redirect_to unsupported_browser_path unless browser.modern?
  end

  # ✅ Admin-only access control (call this manually in admin-only controllers)
  def require_admin
    unless current_user&.admin?
      redirect_to root_path, alert: "Access denied!"
    end
  end
end
