# frozen_string_literal: true

require "csv"

puts "🌱 Seeding database..."

# ---------------------------
# Provinces (idempotent)
# ---------------------------
puts "➡️ Seeding provinces..."
[
  { name: "Alberta",                   pst: 0.00,    gst: 0.05, hst: 0.00 },
  { name: "British Columbia",          pst: 0.07,    gst: 0.05, hst: 0.00 },
  { name: "Manitoba",                  pst: 0.07,    gst: 0.05, hst: 0.00 },
  { name: "New Brunswick",             pst: 0.00,    gst: 0.00, hst: 0.15 },
  { name: "Newfoundland and Labrador", pst: 0.00,    gst: 0.00, hst: 0.15 },
  { name: "Nova Scotia",               pst: 0.00,    gst: 0.00, hst: 0.15 },
  { name: "Ontario",                   pst: 0.00,    gst: 0.00, hst: 0.13 },
  { name: "Prince Edward Island",      pst: 0.00,    gst: 0.00, hst: 0.15 },
  { name: "Quebec",                    pst: 0.09975, gst: 0.05, hst: 0.00 },
  { name: "Saskatchewan",              pst: 0.06,    gst: 0.05, hst: 0.00 }
].each do |prov|
  Province.find_or_create_by!(name: prov[:name]) do |p|
    p.pst = prov[:pst]
    p.gst = prov[:gst]
    p.hst = prov[:hst]
  end
end

StaticPage.find_or_create_by!(slug: "about") do |p|
  p.title = "About"
  p.body  = "Write about your store here."
end
StaticPage.find_or_create_by!(slug: "contact") do |p|
  p.title = "Contact"
  p.body  = "Email: support@prairienatural.com\nAddress: …"
end

if defined?(Coupon)
  Coupon.find_or_create_by!(code: "SAVE10") do |c|
    c.discount_type = :percent
    c.value = 10
    c.starts_at = 1.day.ago
    c.ends_at   = 30.days.from_now
    c.max_uses  = 100
    c.active    = true
  end

  Coupon.find_or_create_by!(code: "WELCOME5") do |c|
    c.discount_type = :amount
    c.value = 5.00
    c.starts_at = Time.current
    c.active    = true
  end
end

# ---------------------------
# Categories (canonical 5)
# ---------------------------
puts "➡️ Creating categories..."
%w[Vitamins Protein\ Supplements Digestive\ Health Skin\ Care Hair\ Care].each do |name|
  Category.find_or_create_by!(name: name)
end

# ---------------------------
# Products from CSV
# ---------------------------
puts "➡️ Importing products from CSV..."
csv_path = Rails.root.join("db/data/iherb_products.csv")
if !File.exist?(csv_path)
  puts "⚠️ CSV not found at #{csv_path}"
else
  created = updated = skipped = 0
  headers = nil

  CSV.foreach(csv_path, headers: true).with_index(2) do |row, i|
    headers      ||= row.headers
    name           = row["name"].to_s.strip.presence || row["title"].to_s.strip
    price_str      = row["price"].to_s
    rating_str     = row["rating"].to_s
    link           = (row["link-href"].presence || row["link"].presence)
    image_url      = (row["image-src"].presence || row["image_url"].presence)
    csv_category   = row["category"].to_s.strip

    if name.blank?
      skipped += 1
      next
    end

    price = price_str.gsub(/[^\d\.]/, "").presence&.to_d || 0

    rating_value = rating_str[/\A\s*([\d.]+)/, 1]&.to_f
    review_count = rating_str[/-\s*([\d,]+)\s+Reviews/i, 1]&.delete(",")&.to_i

    category =
      if csv_category.present?
        Category.find_or_create_by!(name: csv_category)
      else
        Category.find_or_create_by!(name: "Vitamins")
      end

    product =
      if link.present?
        Product.find_or_initialize_by(link: link)
      else
        Product.find_or_initialize_by(name: name, category_id: category.id)
      end

    product.name          ||= name[0, 200]
    product.price           = price
    product.rating          = (rating_value if rating_value&.positive?)
    product.review_count    = review_count if review_count
    product.image_url       = image_url if product.respond_to?(:image_url)
    product.category_id     = category.id

    if product.new_record?
      product.save!
      created += 1
    else
      if product.changed?
        product.save!
        updated += 1
      end
    end

    if image_url.present? && product.respond_to?(:images) && !product.images.attached?
      begin
        fname = File.basename(URI(image_url).path.presence || "image.jpg")
        file  = URI.open(image_url, open_timeout: 8, read_timeout: 12)
        product.images.attach(io: file, filename: fname)
      rescue => e
        Rails.logger.warn("CSV image attach failed for #{product.id}: #{e.message}")
      end
    end
  rescue => e
    puts "❌ Row #{i} failed (headers: #{headers.inspect}): #{e.class} – #{e.message}"
  end

  puts "✅ CSV import done. Created: #{created}, Updated: #{updated}, Skipped: #{skipped}"
end

# ---------------------------
# Walmart API (inline, no system())
# ---------------------------
puts "➡️ Importing Walmart API products..."

begin
  require Rails.root.join("app/services/walmart_serpapi_importer")
  importer = WalmartSerpapiImporter.new

  keywords = [ "ashwagandha", "turmeric", "lavender oil" ]
  limit    = 90

  prev_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :inline

  keywords.each_with_index do |kw, idx|
    puts "➡️  [#{idx + 1}/#{keywords.size}] Importing #{limit} items for: '#{kw}'"
    count = importer.import_keyword(kw, limit: limit)
    puts "   → Imported #{count} items for '#{kw}'"
    puts
  end
ensure
  ActiveJob::Base.queue_adapter = prev_adapter
end

puts "📊 Import Summary:"
%w[Vitamins Protein\ Supplements Digestive\ Health Skin\ Care Hair\ Care].each do |cat|
  c = Category.find_by(name: cat)
  puts "   #{cat}: #{c&.products&.count || 0} products"
end
puts "🎯 Walmart import completed!"

# ---------------------------
# Admin + sample comments
# ---------------------------
puts "➡️ Seeding admin user..."
admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@prairienaturals.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "prairienaturals")

AdminUser.find_or_create_by!(email: admin_email) do |admin|
  admin.password              = admin_password
  admin.password_confirmation = admin_password
end

if AdminUser.any? && Product.any?
  puts "➡️ Creating sample comments..."
  admin   = AdminUser.first
  product = Product.first

  5.times do |i|
    ActiveAdmin::Comment.create!(
      namespace: "admin",
      body: "This is a sample comment ##{i + 1} for testing.",
      resource: product,
      author: admin
    )
  end
  puts "✅ Added 5 sample comments."
else
  puts "⚠️ No AdminUser or Product found — skipping comment seeding."
end

puts "✅ Seeding completed!"
