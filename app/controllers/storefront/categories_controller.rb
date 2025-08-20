class Storefront::CategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: :show, raise: false

  def show
    @is_homepage = false

    @category = Category.friendly.find(params[:id])
    @categories = Category.order(:name)

    scope = Product.includes(:category).where(category_id: @category.id)

    if (q = params[:q].presence || params[:search].presence)
      like = "%#{q}%"
      scope =
        scope.where(
          "products.name ILIKE :like OR products.description ILIKE :like",
          like: like
        )
    end

    case params[:filter]
    when "new"
      scope = scope.where("products.created_at >= ?", 30.days.ago)
    when "sale"
      scope =
        scope.where(
          "products.sale_price IS NOT NULL AND products.sale_price < products.price"
        )
    when "recent"
      scope = scope.order(updated_at: :desc)
    end

    @products =
      case params[:sort]
      when "price_asc"
        scope.order(price: :asc)
      when "price_desc"
        scope.order(price: :desc)
      when "rating"
        scope.order(Arel.sql("COALESCE(products.average_rating, 0) DESC"))
      when "newest"
        scope.order(created_at: :desc)
      else
        scope.order(Arel.sql("LOWER(products.name) ASC"))
      end

    @products = @products.page(params[:page]).per(18) # Kaminari

    params[:category_id] = @category.id

    render "storefront/products/index"
  end
end
