namespace :products do
  desc "Backfill product.image_url from ActiveStorage"
  task backfill_images: :environment do
    Rails.application.routes.default_url_options[:host] = "prairie-naturals.onrender.com"
    Rails.application.routes.default_url_options[:protocol] = "https"

    updated = 0
    Product.includes(images_attachments: :blob).find_each do |p|
      next if p.image_url.present?
      next unless p.images.attached?
      url = Rails.application.routes.url_helpers.rails_blob_url(p.images.first)
      p.update_column(:image_url, url)
      updated += 1
    end
    puts "Updated #{updated} products."
  end
end
