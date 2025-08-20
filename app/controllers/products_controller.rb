class ProductsController < ApplicationController
  before_action :set_product, only: %i[show edit update destroy]

  def index
    @categories = Category.order(:name)
    @products = Product.includes(:category).order(created_at: :desc)

    if params[:category_id].present?
      @products = @products.where(category_id: params[:category_id])
    end

    # Pagination with Kaminari (12 per page)
    @products = @products.page(params[:page]).per(12)
  end

  def index
    @products =
      Product.includes(images_attachments: :blob).order(created_at: :desc)
  end

  def show
    @product = Product.includes(images_attachments: :blob).find(params[:id])
  end

  def new
    @product = Product.new
  end

  # GET /products/:id/edit
  def edit
  end

  # POST /products
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html do
          redirect_to @product, notice: "Product was successfully created."
        end
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json do
          render json: @product.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # PATCH/PUT /products/:id
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html do
          redirect_to @product, notice: "Product was successfully updated."
        end
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json do
          render json: @product.errors, status: :unprocessable_entity
        end
      end
    end
  end

  # DELETE /products/:id
  def destroy
    @product.destroy!
    respond_to do |format|
      format.html do
        redirect_to products_path,
                    notice: "Product was successfully destroyed.",
                    status: :see_other
      end
      format.json { head :no_content }
    end
  end

  private

  # Find product by slug (FriendlyId)
  def set_product
    @product = Product.friendly.find(params[:id])
  end

  # Strong parameters
  def product_params
    params.require(:product).permit(
      :name,
      :description,
      :price,
      :image,
      :category_id
    )
  end
end
