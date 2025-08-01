module Storefront
  class ProductsController < ApplicationController
    def index
      @categories = Category.all
      @products = Product.includes(:category)

      if params[:category_id].present?
        @products = @products.where(category_id: params[:category_id])
      end

      if params[:search].present?
        @products = @products.where("name ILIKE ?", "%#{params[:search]}%")
      end

      @products = @products.page(params[:page]).per(2)
    end

    def show
      @product = Product.friendly.find(params[:id])
    end
  end
end
