# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    # keep public
    skip_before_action :authenticate_user!, only: %i[index show], raise: false

    def index
      # ONLY "/" is homepage; "/storefront/products" is the PLP
      @is_homepage = (request.path == root_path)

      @categories = Category.order(:name)

      # Base scope
      scope = Product.includes(:category)

      # Optional: category filter (used by PLP UI and by CategoriesController)
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?

      # Search
      if (q = params[:q].presence || params[:search].presence)
        like  = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      # Filters
      case params[:filter]
      when "new"    then scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"   then scope = scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent" then scope = scope.order(updated_at: :desc)
      end

      # Sorting
      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"     then scope.order(Arel.sql("COALESCE(products.average_rating, 0) DESC"))
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      # Pagination
      @products = @products.page(params[:page]).per(18)
    end

    def show
      @product = Product.friendly.find(params[:id])
      @reviews = @product.reviews.includes(:user).order(created_at: :desc) if @product.respond_to?(:reviews)

      @related_products = Product.where(category_id: @product.category_id)
                                 .where.not(id: @product.id)
                                 .limit(6)

      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.take(5)

      recent_ids = session[:recently_viewed] - [@product.id]
      @recently_viewed_products = Product.where(id: recent_ids)
    end
  end
end
