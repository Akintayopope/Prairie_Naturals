module Storefront
  class ProductsController < ApplicationController
    def index
      @products = Product.includes(:category).all
    end

    def show
      @product = Product.friendly.find(params[:id])
    end
  end
end
