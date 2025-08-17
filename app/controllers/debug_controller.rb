class DebugController < ApplicationController
  def image_counts
    counts = Product.left_joins(:images_attachments)
                    .group(:id)
                    .select("products.id, products.name, COUNT(active_storage_attachments.id) AS images_count")

    render json: counts.map { |p| { id: p.id, name: p.name, images_count: p.images_count } }
  end
end
