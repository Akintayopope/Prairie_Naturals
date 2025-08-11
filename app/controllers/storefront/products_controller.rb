# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    # Storefront should be public; skip Devise auth here
    skip_before_action :authenticate_user!, only: %i[index show]

    def index
      @categories = Category.order(:name)

      @products = Product.includes(:category)

      if params[:search].present?
        q = "%#{params[:search]}%"
        @products = @products.where("name ILIKE :q OR title ILIKE :q", q: q)
      end

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      case params[:filter]
      when "new"
        @products = @products.order(created_at: :desc)
      when "sale"
        @products = @products.where("sale_price IS NOT NULL AND sale_price < price")
      when "recent"
        @products = @products.order(updated_at: :desc)
      else
        # stable, case-insensitive alphabetical default
        @products = @products.order(Arel.sql("LOWER(name) ASC"))
      end

      @products = @products.page(params[:page]).per(6)
    end

    def show
      @product = Product.friendly.find(params[:id])

      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(4)

      # -- Recently viewed: keep newest-first, unique, max 5, store int ids --
      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.first(5)

      recent_ids = session[:recently_viewed] - [@product.id]
      @recently_viewed_products = Product.where(id: recent_ids)

      # If you have reviews, eager-load user; otherwise stay harmless
      @reviews = @product.respond_to?(:reviews) ? @product.reviews.includes(:user).order(created_at: :desc) : []
    end
  end
end
