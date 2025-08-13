# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    skip_before_action :authenticate_user!, only: %i[index show], raise: false

    HOMEPAGE_FEATURED_LIMIT = 18

    def index
      @categories = Category.alphabetical

      @is_homepage = params.slice(:q, :search, :category_id, :filter, :sort).values.all?(&:blank?)

      if @is_homepage
        base = Product
                 .includes(:category, images_attachments: :blob)
                 .in_stock
                 .where("price IS NOT NULL AND price > 0")
                 .order(Arel.sql("COALESCE(rating, 0) DESC NULLS LAST, created_at DESC"))
                 .limit(48)

        # Prefer products with images, then fill from the rest
        with_img, without_img = base.partition { |p| p.images.attached? || p.image_url.present? }
        @featured_products = (with_img + without_img).first(HOMEPAGE_FEATURED_LIMIT)
      end

      # === existing catalog behavior ===
      scope = Product.includes(:category)
      if (q = (params[:q].presence || params[:search].presence))
        like = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end
      scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
      case params[:filter]
      when "new"   then scope = scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"  then scope = scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent" then scope = scope.order(updated_at: :desc)
      end

      @products =
        case params[:sort]
        when "price_asc"  then scope.order(price: :asc)
        when "price_desc" then scope.order(price: :desc)
        when "rating"     then scope.order(Arel.sql("COALESCE(products.average_rating, COALESCE(products.rating, 0)) DESC"))
        when "newest"     then scope.order(created_at: :desc)
        else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
        end

      @products = @products.page(params[:page]).per(18)
    end
  end
end
