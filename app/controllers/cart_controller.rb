class CartController < ApplicationController
  def show
    if user_signed_in?
      @cart_items = current_user.cart_items.includes(:product)
    else
      @cart_items = session[:cart] || {}
      @products = Product.friendly.where(slug: @cart_items.keys)
    end
  end

  def add_item
  product = Product.friendly.find(params[:product_id])
  product_id = product.slug

  if user_signed_in?
    cart_item = current_user.cart_items.find_or_initialize_by(product: product)
    cart_item.quantity ||= 0  # Fix: Initialize to 0 if nil
    cart_item.quantity += 1
    cart_item.save!
  else
    session[:cart] ||= {}
    session[:cart][product_id] = (session[:cart][product_id] || 0) + 1
  end

  Rails.logger.info "🛒 Added product #{product_id} to cart."
  redirect_to cart_path, notice: "Cart updated successfully."
end

  def update_quantities
    if user_signed_in?
      update_user_cart_quantities
    else
      update_guest_cart_quantities
    end

    redirect_to cart_path, notice: "Cart updated successfully."
  end

  def remove_item
    product = Product.friendly.find(params[:product_id])

    if user_signed_in?
      current_user.cart_items.where(product: product).destroy_all
    else
      session[:cart]&.delete(product.slug)
    end

    redirect_to cart_path, notice: "Item removed from cart."
  end

  private

  def update_user_cart_quantities
    params[:quantities]&.each do |item_id, quantity|
      item = current_user.cart_items.find_by(id: item_id)
      next unless item

      quantity = quantity.to_i
      quantity <= 0 ? item.destroy : item.update(quantity: quantity)
    end
  end

  def update_guest_cart_quantities
    session[:cart] ||= {}
    params[:quantities]&.each do |product_slug, quantity|
      quantity = quantity.to_i
      quantity <= 0 ? session[:cart].delete(product_slug) : session[:cart][product_slug] = quantity
    end
  end
end
