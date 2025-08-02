class CartController < ApplicationController
  def show
    @cart = session[:cart] || {}
    @products = Product.find(@cart.keys)
  end

  def add_item
    session[:cart] ||= {}
    product_id = params[:product_id].to_s
    session[:cart][product_id] = (session[:cart][product_id] || 0) + 1

    redirect_to cart_path, notice: 'Product added to cart.'
  end

  def remove_item
    product_id = params[:product_id].to_s
    session[:cart]&.delete(product_id)

    redirect_to cart_path, notice: 'Product removed from cart.'
  end
end
