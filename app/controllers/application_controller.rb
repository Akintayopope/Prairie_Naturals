# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # CSRF protection (Rails default)
  protect_from_forgery with: :exception

  protect_from_forgery with: :null_session, prepend: true

  # Flash helpers
  add_flash_types :success, :warning, :info

  # Layout/page helpers
  before_action :set_is_homepage
  before_action :require_modern_browser
  before_action :set_cart_badge, unless: :skip_cart_for_admin?

  # Devise strong params
  before_action :configure_permitted_parameters, if: :devise_controller?

  # View helpers
  helper_method :cart_count, :cart_total, :current_storefront_user

  protected

  # Allow extra attributes on Devise forms (only for User, not AdminUser)
  def configure_permitted_parameters
    return unless devise_mapping.name == :user

    address_attrs = %i[line1 line2 city postal_code province_id]
    extra_keys = [
      :username,
      :province_id,
      { address_attributes: address_attrs }
    ]

    devise_parameter_sanitizer.permit(:sign_up, keys: extra_keys)
    devise_parameter_sanitizer.permit(:account_update, keys: extra_keys)
  end

  # After any Devise sign-in, merge guest cart into *storefront* user's cart.
  # Strict guard ensures it never runs for AdminUser.
  def after_sign_in_path_for(resource)
    if session[:cart].present? && resource.is_a?(::User)
      CartMerger.new(resource, session[:cart]).merge!
      session.delete(:cart)
    end

    # Redirect admins to their appropriate area
    if resource.is_a?(::AdminUser)
      admin_root_path
    else
      super
    end
  end

  private

  # Skip cart processing for admin-related requests
  def skip_cart_for_admin?
    request.path.start_with?('/admin') ||
    self.class.name.include?('ActiveAdmin') ||
    controller_path.include?('admin')
  rescue
    false
  end

  # Helper method to get storefront user safely
  def current_storefront_user
    return nil unless respond_to?(:user_signed_in?)
    return nil unless user_signed_in?
    return nil unless current_user.is_a?(::User)
    current_user
  end

  # Whether current request is the homepage (used by layout)
  def set_is_homepage
    @is_homepage = (request.path == root_path)
  rescue StandardError
    @is_homepage = false
  end

  # Placeholder for any browser checks/redirects you want to enforce
  def require_modern_browser
    # no-op for now
  end

  # Admin authentication - works with separate AdminUser model
  def require_admin
    unless respond_to?(:admin_user_signed_in?) && admin_user_signed_in?
      redirect_to new_admin_user_session_path, alert: "Please sign in as an administrator."
    end
  end

  # Ensure only storefront users can access certain areas
  def require_storefront_user
    unless current_storefront_user
      redirect_to new_user_session_path, alert: "Please sign in to continue."
    end
  end

  # Expose counts/totals to views; default to 0 when empty
  def cart_count
    @cart_count || 0
  end

  def cart_total
    @cart_total || 0
  end

  # Compute cart metrics for header/cart badge.
  # This method will NOT be called for admin requests due to skip_cart_for_admin? guard
  def set_cart_badge
    @cart_count = 0
    @cart_total = 0.to_d

    # Handle logged-in storefront users with database cart
    if current_storefront_user&.respond_to?(:cart_items)
      items = current_storefront_user.cart_items.includes(:product)
      @cart_count = items.sum(:quantity)
      @cart_total = items.sum { |ci| ci.quantity.to_i * (ci.product&.price.to_d || 0) }
    else
      # Handle guest cart from session
      cart = session[:cart] || {}
      @cart_count = cart.values.sum(&:to_i)

      if cart.any?
        products_by_slug = Product.friendly.where(slug: cart.keys).index_by(&:slug)
        @cart_total = cart.sum do |slug, qty|
          price = products_by_slug[slug]&.price.to_d || 0.to_d
          qty.to_i * price
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error in set_cart_badge: #{e.message}"
    @cart_count = 0
    @cart_total = 0.to_d
  end

  class CartMerger
    def initialize(user, session_cart)
      @user = user
      @session_cart = session_cart || {}
    end


    def merge!
      return if @session_cart.blank?
      return unless @user.is_a?(::User)

      products_by_slug = Product.friendly.where(slug: @session_cart.keys).index_by(&:slug)

      @session_cart.each do |slug, qty|
        qty_i = qty.to_i
        next if qty_i <= 0

        product = products_by_slug[slug]
        next unless product

        item = @user.cart_items.find_or_initialize_by(product: product)
        item.quantity = item.quantity.to_i + qty_i
        item.save!
      end
    end
  end
end