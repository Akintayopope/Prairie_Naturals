# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    def index
      @categories = Category.order(:name)

      # Base scope
      scope = Product.includes(:category)

      # --- Search (q or search) ---
      q = params[:q].presence || params[:search].presence
      if q
        like = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      # --- Category filter ---
      if params[:category_id].present?
        scope = scope.where(category_id: params[:category_id])
      end

      # --- Show filter ---
      case params[:filter]
      when "new"
        scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"
        scope = scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent"
        scope = scope.order(updated_at: :desc)
      end

      # --- Sorting ---
      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"
          # If you store ratings on products table; otherwise adjust to your reviews agg
          scope.order(Arel.sql("COALESCE(products.average_rating, 0) DESC"))
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      # --- Pagination: 18 per page (6 × 3) ---
      @products = @products.page(params[:page]).per(18)  # Kaminari
      # For will_paginate instead, use:
      # @products = @products.paginate(page: params[:page], per_page: 18)
    end

    def show
      @product = Product.friendly.find(params[:id])

      # Reviews relation (optional)
      @reviews = @product.reviews.includes(:user).order(created_at: :desc) if @product.respond_to?(:reviews)

      # Related
      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(4)

      # Recently viewed (dedupe, most recent first, max 5)
      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.take(5)

      recent_ids = session[:recently_viewed] - [@product.id]
      @recently_viewed_products = Product.where(id: recent_ids)
    end
  end
end
