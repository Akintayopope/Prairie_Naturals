class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

  DEFAULT_PER_PAGE = 12

  # GET /products
  def index
    scope = Product
              .includes(:category, images_attachments: :blob)
              .order(created_at: :desc)

    scope = scope.where(category_id: params[:category_id]) if params[:category_id].present?
    @categories = Category.order(:name)
    @products   = scope.page(params[:page]).per(DEFAULT_PER_PAGE)
  end

  # GET /products/:id
  def show
    # @product loaded via FriendlyId; just eager-load attachments for the view
    @product = Product.includes(images_attachments: :blob).find(@product.id)
  end

  def new
    @product = Product.new
  end

  def edit; end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to @product, notice: "Product was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @product.update(product_params)
      redirect_to @product, notice: "Product was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy!
    redirect_to products_path, notice: "Product was successfully destroyed.", status: :see_other
  end

  private

  def set_product
    @product = Product.friendly.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :image, :category_id)
  end
end
