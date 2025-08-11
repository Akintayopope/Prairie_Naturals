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
      when "new"
        @products = @products.order(created_at: :desc)
      when "sale"
        @products = @products.where("sale_price IS NOT NULL AND sale_price < price")
      when "recent"
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

      @recently_viewed_products = Product.find(session[:recently_viewed] - [ @product.id ])
    end
  end
end# app/controllers/storefront/products_controller.rb
module Storefront
  class ProductsController < ApplicationController
    def index
      @categories = Category.order(:name)
      @products   = Product.includes(:category)

      if params[:search].present?
        @products = @products.where("name ILIKE ?", "%#{params[:search]}%")
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
        @products = @products.order(Arel.sql("LOWER(name) ASC"))
      end

      @products = @products.page(params[:page]).per(6)
    end

    def show
      @product = Product.friendly.find(params[:id])

      # Always set @reviews to a relation (not nil) and eager load user if present
      @reviews = @product.reviews.includes(:user).order(created_at: :desc)

      @related_products = Product
                            .where(category_id: @product.category_id)
                            .where.not(id: @product.id)
                            .limit(4)

      # -- Recently viewed (dedupe, keep newest first, max 5) --
      session[:recently_viewed] ||= []
      session[:recently_viewed].delete(@product.id)
      session[:recently_viewed].unshift(@product.id)
      session[:recently_viewed] = session[:recently_viewed].uniq.take(5)

      recent_ids = session[:recently_viewed] - [ @product.id ]
      @recently_viewed_products = Product.where(id: recent_ids)
    end
  end
end
