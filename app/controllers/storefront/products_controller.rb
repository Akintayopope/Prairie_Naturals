# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show], raise: false

    def index
      # Homepage only when visiting "/"
      @is_homepage = (request.path == root_path)

      # Used by the homepage quick-categories
      @categories = Category.order(:name)

      if @is_homepage
        # ---- HOMEPAGE DATA ----
        # Choose what "featured" means for you:
        @featured_products = Product.in_stock.order(created_at: :desc).limit(12)
        # If you prefer curated picks, add a boolean :featured column and use:
        # @featured_products = Product.in_stock.where(featured: true).order(updated_at: :desc).limit(12)
        return
      end

      # ---- PLP (LISTING) ----
      scope = Product.includes(:category)

      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

      if (q = params[:q].presence || params[:search].presence)
        like  = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      case params[:filter]
      when "new"    then scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"   then scope = scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent" then scope = scope.order(updated_at: :desc)
      end

      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"     then scope.order(Arel.sql("COALESCE(products.rating, 0) DESC"))  # use your existing :rating column
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      @products = @products.page(params[:page]).per(18)
    end

    def show
      @product = Product.friendly.find(params[:id])

      # If you removed review-writing, it's safe to skip loading them:
      @reviews = @product.reviews.includes(:user).order(created_at: :desc) if @product.respond_to?(:reviews)

      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(6)

      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.take(6)

      recent_ids = session[:recently_viewed] - [@product.id]
      @recently_viewed_products = Product.where(id: recent_ids)
    end
  end
end
