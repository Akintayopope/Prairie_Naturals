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

  # ✅ Merge session cart into database cart after user logs in
  def after_sign_in_path_for(resource)
    if session[:cart]
      session[:cart].each do |slug, qty|
        product = Product.friendly.find_by(slug: slug)
        next unless product

        item = resource.cart_items.find_or_initialize_by(product: product)
        item.quantity += qty.to_i
        item.save!
      end
      session[:cart] = nil
    end

    super
  end
end
