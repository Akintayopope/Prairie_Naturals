# app/controllers/storefront/categories_controller.rb
module Storefront
  class CategoriesController < ApplicationController
    # Keep category browsing public (avoid the earlier skip error with raise: false)
    skip_before_action :authenticate_user!, only: :show, raise: false

    def show
      @is_homepage = false

      @category   = Category.friendly.find(params[:id])
      @categories = Category.order(:name)

      # === Base scope (same shape as storefront/products#index) ===
      scope = Product.includes(:category).where(category_id: @category.id)

      # --- Search ---
      if (q = params[:q].presence || params[:search].presence)
        like  = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      # --- Filters ---
      case params[:filter]
      when "new"    then scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"   then scope = scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent" then scope = scope.order(updated_at: :desc)
      end

      # --- Sorting ---
      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"     then scope.order(Arel.sql("COALESCE(products.average_rating, 0) DESC"))
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      # --- Pagination ---
      @products = @products.page(params[:page]).per(18)

      # Reuse your existing PLP template
      render "storefront/products/index"
    end
  end
end
