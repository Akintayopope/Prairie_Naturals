# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
before_action :set_is_homepage

def set_is_homepage
    @is_homepage = (request.path == root_path)
  end
  # ❌ Do NOT force auth globally (breaks public storefront)
  before_action :authenticate_user!, unless: :devise_controller?

  before_action :require_modern_browser
  before_action :set_cart_badge

  # Allow extra Devise params (username + nested address)
  before_action :configure_permitted_parameters, if: :devise_controller?

  helper_method :cart_count, :cart_total

  protected

  def configure_permitted_parameters
    address_attrs = [:line1, :line2, :city, :postal_code, :province_id]
    devise_parameter_sanitizer.permit(:sign_up,        keys: [:username, address_attributes: address_attrs])
    devise_parameter_sanitizer.permit(:account_update, keys: [:username, address_attributes: address_attrs])
  end

  private

  # Optional: modern browser check
  def require_modern_browser
    # redirect_to unsupported_browser_path unless browser.modern?
  end

  # Admin-only access control (use in admin-only custom controllers if needed)
  def require_admin
    redirect_to root_path, alert: "Access denied!" unless current_user&.admin?
  end

  # Merge session cart into DB cart after login
  def after_sign_in_path_for(resource)
    if session[:cart].present?
      session[:cart].each do |slug, qty|
        product = Product.friendly.find_by(slug: slug)
        next unless product
        item = resource.cart_items.find_or_initialize_by(product: product)
        item.quantity = item.quantity.to_i + qty.to_i
        item.save!
      end
      session.delete(:cart)
    end
    super
  end

  # Cart badge helpers
  def cart_count
    @cart_count || 0
  end

  def cart_total
    @cart_total || 0
  end

  def set_cart_badge
    if user_signed_in?
      items = current_user.cart_items.includes(:product)
      @cart_count = items.sum(:quantity)
      @cart_total = items.sum { |ci| ci.quantity.to_i * ci.product.price.to_d }
    else
      cart = session[:cart] || {} # {"slug" => qty}
      @cart_count = cart.values.map(&:to_i).sum
      if cart.any?
        products = Product.friendly.where(slug: cart.keys).index_by(&:slug)
        @cart_total = cart.sum { |slug, qty| qty.to_i * (products[slug]&.price.to_d || 0.to_d) }
      else
        @cart_total = 0.to_d
      end
    end
  end
end
