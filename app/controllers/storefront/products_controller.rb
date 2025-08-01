# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    def index
      @categories = Category.all
      @products = Product.includes(:category)

      if params[:search].present?
        @products = @products.where("name ILIKE ?", "%#{params[:search]}%")
      end

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      case params[:filter]
      when 'new'
        @products = @products.order(created_at: :desc)
      when 'sale'
        @products = @products.where("sale_price IS NOT NULL AND sale_price < price")
      when 'recent'
        @products = @products.order(updated_at: :desc)
      end

      @products = @products.page(params[:page]).per(6)
    end

    def show
      @product = Product.friendly.find(params[:id])

      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(4)

      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].take(5)

      @recently_viewed_products = Product.find(session[:recently_viewed] - [@product.id])
    end
  end
end
