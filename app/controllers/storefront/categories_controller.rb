# app/controllers/storefront/categories_controller.rb
module Storefront
  class CategoriesController < ApplicationController
    skip_before_action :authenticate_user!, only: :show, raise: false
    before_action :set_category

    def show
      @is_homepage = false
      @categories  = Category.order(:name)

      scope = Product
                .includes(:category, images_attachments: :blob, images_blobs: :variant_records)
                .where(category_id: @category.id)

      if (q = safe_query)
        like  = "%#{q}%"
        scope = scope.where("products.name ILIKE :like OR products.description ILIKE :like", like: like)
      end

      scope = apply_filter(scope)
      scope = apply_sort(scope)

      @products = scope.page(page_param).per(per_page_param)

      # Let the PLP view show the category name/chips without changing the template
      params[:category_id] = @category.id

      # Reuse the products index (PLP) view
      render "storefront/products/index"
    end

    private

    def set_category
      @category = Category.friendly.find(params[:id])
    end

    # Normalize search string (strip/squish) and allow blank to mean nil
    def safe_query
      (params[:q].presence || params[:search].presence).to_s.strip.squish.presence
    end

    def apply_filter(scope)
      case filter_param
      when "new"
        scope.where("products.created_at >= ?", 30.days.ago)
      when "sale"
        scope.where("products.sale_price IS NOT NULL AND products.sale_price < products.price")
      when "recent"
        scope.order(updated_at: :desc)
      else
        scope
      end
    end

    def apply_sort(scope)
      case sort_param
      when "price_asc"  then scope.order(price: :asc)
      when "price_desc" then scope.order(price: :desc)
      when "rating"     then scope.order(Arel.sql("COALESCE(products.average_rating, 0) DESC"))
      when "newest"     then scope.order(created_at: :desc)
      else                   scope.order(Arel.sql("LOWER(products.name) ASC"))
      end
    end

    # --- Param guards --------------------------------------------------------

    ALLOWED_FILTERS = %w[new sale recent].freeze
    ALLOWED_SORTS   = %w[price_asc price_desc rating newest name_asc].freeze

    def filter_param
      val = params[:filter].to_s
      ALLOWED_FILTERS.include?(val) ? val : nil
    end

    def sort_param
      val = params[:sort].to_s
      ALLOWED_SORTS.include?(val) ? val : "name_asc"
    end

    def page_param
      (params[:page].presence || 1).to_i
    end

    def per_page_param
      # Keep your 18 default; cap to avoid pathological values
      per = (params[:per].presence || 18).to_i
      per = 18 if per <= 0
      [per, 60].min
    end
  end
end
