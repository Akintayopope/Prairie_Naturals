# db/seeds.rb

require "open-uri"

puts "🌱 Seeding database..."

# ✅ Categories
puts "➡️ Seeding categories..."
categories = %w[Hair Skin Vitamins Supplements Body]
categories.each do |name|
  Category.find_or_create_by!(name: name)
end

# ✅ Provinces
puts "➡️ Seeding provinces..."
[
  { name: "Ontario", pst: 0.08, gst: 0.05, hst: 0.13 },
  { name: "Manitoba", pst: 0.07, gst: 0.05, hst: 0.0 },
  { name: "Alberta", pst: 0.0, gst: 0.05, hst: 0.0 },
  { name: "British Columbia", pst: 0.07, gst: 0.05, hst: 0.0 },
  { name: "Quebec", pst: 0.09975, gst: 0.05, hst: 0.0 }
].each do |prov|
  Province.find_or_create_by!(name: prov[:name]) do |p|
    p.pst = prov[:pst]
    p.gst = prov[:gst]
    p.hst = prov[:hst]
  end
end

# ✅ Products with images
puts "➡️ Seeding products..."
sample_products = [
  { name: "Natural Shampoo", description: "Organic hair shampoo.", price: 12.99, stock: 20, image: "shampoo.jpg", category: "Hair" },
  { name: "Vitamin C Serum", description: "Brightens and repairs skin.", price: 18.49, stock: 15, image: "vitamin.jpg", category: "Skin" },
]

sample_products.each do |prod|
  category = Category.find_by(name: prod[:category])
  product = Product.find_or_create_by!(name: prod[:name], category: category) do |p|
    p.description = prod[:description]
    p.price = prod[:price]
    p.stock = prod[:stock]
  end

  unless product.image.attached?
    image_path = Rails.root.join("db/seeds/images/#{prod[:image]}")
    product.image.attach(io: File.open(image_path), filename: prod[:image])
  end
end

# ✅ Admin User
puts "➡️ Seeding admin user..."
admin_email = ENV.fetch("ADMIN_EMAIL", "admin@prairienaturals.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "prairienaturals")

AdminUser.find_or_create_by!(email: admin_email) do |admin|
  admin.password = admin_password
  admin.password_confirmation = admin_password
end

puts "✅ Seeding completed with products, categories, provinces, and admin user!"
