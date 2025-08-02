class CartController < ApplicationController
  def show
    @cart_items = session[:cart] || {}
    @products = Product.friendly.where(slug: @cart_items.keys)

  end

def add_item
  product = Product.friendly.find(params[:product_id])
  product_id = product.slug

  session[:cart] ||= {}
  session[:cart][product_id] = (session[:cart][product_id] || 0) + 1

  Rails.logger.info "🛒 Added product #{product_id} to cart: #{session[:cart].inspect}"
  redirect_to cart_path, notice: "Cart updated successfully."
end

def update_quantities
  session[:cart] ||= {}

  params[:quantities]&.each do |product_id, quantity|
    quantity = quantity.to_i
    if quantity <= 0
      session[:cart].delete(product_id)
    else
      session[:cart][product_id] = quantity
    end
  end

  redirect_to cart_path, notice: "Cart updated successfully."
end

  def remove_item
    product_id = params[:product_id].to_s
    session[:cart]&.delete(product_id)
    redirect_to cart_path, notice: "Item removed from cart."
  end
end

