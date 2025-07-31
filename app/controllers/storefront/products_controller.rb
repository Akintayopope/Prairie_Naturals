module Storefront
  class ProductsController < ApplicationController
    def index
      @categories = Category.all
      @selected_category = params[:category_id]

      @products = Product.includes(:category)
      @products = @products.where(category_id: @selected_category) if @selected_category.present?
      @products = @products.page(params[:page]).per(6)
    end

    def show
      @product = Product.friendly.find(params[:id])
    end
  end
end

