# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  # CSRF protection (Rails default)
  protect_from_forgery with: :exception
  add_flash_types :success, :warning, :info

  # --- Global before_actions ---
  before_action :set_is_homepage
  before_action :require_modern_browser
  before_action :set_cart_badge

  # Allow extra Devise params on sign-up / account edit
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Expose helpers to views
  helper_method :cart_count, :cart_total

  protected

  # Permit extra Devise params:
  # - user-level :username and :province_id (profile province)
  # - nested :address_attributes (shipping address incl. province)
  def configure_permitted_parameters
    address_attrs = %i[line1 line2 city postal_code province_id]
    extra_keys    = [ :username, :province_id, { address_attributes: address_attrs } ]

    devise_parameter_sanitizer.permit(:sign_up,        keys: extra_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: extra_keys)
  end

  # After login, merge session cart into the user's persisted cart
  def after_sign_in_path_for(resource)
    if session[:cart].present?
      CartMerger.new(resource, session[:cart]).merge!
      session.delete(:cart)
    end
    super
  end

  private

  # True only on the root (homepage). Used by layout/view conditionals.
  def set_is_homepage
    @is_homepage = (request.path == root_path)
  rescue
    @is_homepage = false
  end

  # Optional: gate older/unsupported browsers
  def require_modern_browser
    # redirect_to unsupported_browser_path unless browser.modern?
  end

  # Admin-only guard for custom admin controllers (ActiveAdmin has its own)
  def require_admin
    redirect_to root_path, alert: "Access denied!" unless current_user&.admin?
  end

  # Cart badge helpers (count + total) for header UI
  def cart_count
    @cart_count || 0
  end

  def cart_total
    @cart_total || 0
  end

  # Compute cart metrics for signed-in users vs. session carts
  def set_cart_badge
    if user_signed_in?
      items       = current_user.cart_items.includes(:product)
      @cart_count = items.sum(:quantity)
      @cart_total = items.to_a.sum { |ci| ci.quantity.to_i * (ci.product&.price.to_d || 0.to_d) }
    else
      cart        = session[:cart] || {} # {"slug" => qty}
      @cart_count = cart.values.map(&:to_i).sum

      if cart.any?
        products = Product.friendly.where(slug: cart.keys).index_by(&:slug)
        @cart_total = cart.sum do |slug, qty|
          qty.to_i * (products[slug]&.price.to_d || 0.to_d)
        end
      else
        @cart_total = 0.to_d
      end
    end
  end

  # --- Small PORO to keep after_sign_in_path_for clean ---
  class CartMerger
    def initialize(user, session_cart)
      @user         = user
      @session_cart = session_cart || {}
    end

    def merge!
      return if @session_cart.blank?

      products = Product.friendly.where(slug: @session_cart.keys).index_by(&:slug)

      @session_cart.each do |slug, qty|
        product = products[slug]
        next unless product

        item = @user.cart_items.find_or_initialize_by(product: product)
        item.quantity = item.quantity.to_i + qty.to_i
        item.save!
      end
    end
  end
end
