require "open-uri"
require "json"

namespace :import do
  desc "Import products from Open Food Facts API"
  task openfood: :environment do
    url = "https://world.openfoodfacts.org/category/dietary-supplements.json"
    puts "🌐 Fetching data from: #{url}"

    begin
      response = URI.open(url).read
      data = JSON.parse(response)
      products = data["products"].first(50) # just a few to test

      products.each do |item|
        name = item["product_name"]&.strip
        next if name.blank?

        category_name = item["categories_tags"]&.first&.titleize || "Supplements"
        image_url = item["image_front_url"]
        description = item["brands"] || "Imported from Open Food Facts"
        price = rand(8.0..30.0).round(2)
        stock = rand(10..50)

        category = Category.find_or_create_by!(name: category_name)
        product = Product.find_or_create_by!(name: name, category: category) do |p|
          p.description = description
          p.price = price
          p.stock = stock
        end

        if image_url && !product.image.attached?
          begin
            file = URI.open(image_url)
            filename = File.basename(URI.parse(image_url).path)
            product.image.attach(io: file, filename: filename)
          rescue => e
            puts "⚠️ Failed to attach image for #{name}: #{e.message}"
          end
        end

        puts "✅ Saved: #{name} ($#{price}) – #{category.name}"
      end

      puts "🎉 Done importing from Open Food Facts!"

    rescue => e
      puts "❌ Error: #{e.message}"
    end
  end
end
