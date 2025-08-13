module Storefront
  class ProductsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show], raise: false

    def index
      # Homepage only when you are at "/" AND there are no filters/search/pagination
      @is_homepage = (request.path == root_path) &&
                     params.slice(:q, :search, :category_id, :filter, :sort, :page)
                           .values
                           .all?(&:blank?)

      @categories = Category.order(:name)

      # ---------- HOMEPAGE DATA ----------
      if @is_homepage
        # Give the home partials data to render
        @featured_products = Product.order(created_at: :desc).limit(12)
        @new_products      = Product.order(created_at: :desc).limit(12)  # optional if your partial uses it
        # Also expose @products so a grid partial wouldn’t break if it’s reused
        @products = @featured_products
        return
      end

      # ---------- PLP DATA ----------
      scope = Product.includes(:category)

      # Category filter (works for PLP and when CategoriesController forwards here)
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

      # Search
      if (q = params[:q].presence || params[:search].presence)
        like = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      # Filters
      case params[:filter]
      when "new"
        scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"
        scope = scope.where.not(sale_price: nil).where("sale_price < price")
      when "recent"
        scope = scope.order(updated_at: :desc)
      end

      # Sorting (use reviews for rating; fall back to name)
      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"
          scope.left_outer_joins(:reviews)
               .group("products.id")
               .order(Arel.sql("COALESCE(AVG(reviews.rating), 0) DESC, LOWER(products.name) ASC"))
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      # Pagination (Kaminari)
      @products = @products.page(params[:page]).per(18)
    end

    def show
      @product = Product.friendly.find(params[:id])
      @reviews = @product.reviews.includes(:user).order(created_at: :desc) if @product.respond_to?(:reviews)

      # You might also like (6)
      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(6)

      # Recently viewed (keep last 6)
      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.take(6)

      recent_ids = session[:recently_viewed] - [@product.id]
      @recently_viewed_products = Product.where(id: recent_ids).limit(6)
    end
  end
end
