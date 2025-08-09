# app/helpers/products_helper.rb
module ProductsHelper
  def product_main_image(product)
    if product.images.attached?
      product.images.first
    else
      nil # or a placeholder logic
    end
  end

  def product_variant(image, size: [400, 400])
    # Use :resize_to_fill or :resize_to_limit as you prefer
    image.variant(resize_to_limit: size)
  end

  def product_placeholder
    image_path("placeholder-product.png") # add one in app/assets/images/
  end
end
