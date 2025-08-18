module ProductsHelper
  def product_primary_image(product, size: [1200, 1500])
    if product.images.attached?
      att = product.images.first
      begin
        image_tag att.variant(resize_to_limit: size),
                  alt: product.name, loading: "lazy", decoding: "async"
      rescue => e
        Rails.logger.warn("variant failed: #{e.class}: #{e.message}")
        image_tag url_for(att), alt: product.name, loading: "lazy", decoding: "async"
      end
    elsif product.image_url.present?
      image_tag product.image_url,
                alt: product.name, loading: "lazy", decoding: "async"
    end
  end
end
