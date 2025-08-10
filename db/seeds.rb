require "csv"

puts "🌱 Seeding database..."

# ===============================
# Provinces (idempotent upserts)
# ===============================
puts "➡️ Seeding provinces..."
[
  { name: "Ontario",            pst: 0.08,    gst: 0.05, hst: 0.13 },
  { name: "Manitoba",           pst: 0.07,    gst: 0.05, hst: 0.00 },
  { name: "Alberta",            pst: 0.00,    gst: 0.05, hst: 0.00 },
  { name: "British Columbia",   pst: 0.07,    gst: 0.05, hst: 0.00 },
  { name: "Quebec",             pst: 0.09975, gst: 0.05, hst: 0.00 }
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


# =========================
# Categories (final 5)
# =========================
puts "➡️ Creating categories..."
categories = %w[Vitamins Protein\ Supplements Digestive\ Health Skin\ Care Hair\ Care]
categories.each { |name| Category.find_or_create_by!(name: name) }

# =========================
# Products from CSV (into 3 categories)
# =========================
puts "➡️ Importing products from CSV..."
csv_path = Rails.root.join("db/data/iherb_products.csv")
if !File.exist?(csv_path)
  puts "⚠️ CSV not found at #{csv_path}"
else
  vitamins         = Category.find_or_create_by!(name: "Vitamins")
  protein_supp     = Category.find_or_create_by!(name: "Protein Supplements")
  digestive_health = Category.find_or_create_by!(name: "Digestive Health")

  def map_csv_category(name, vitamins, protein_supp, digestive_health)
    down = name.to_s.downcase
    return vitamins         if down.include?("vitamin")
    return protein_supp     if down.include?("protein") || down.include?("whey") || down.include?("collagen")
    return digestive_health if down.include?("digest")  || down.include?("probiotic") || down.include?("fiber")
    vitamins
  end

  require "csv"
  require "open-uri"

  created = updated = skipped = 0
  headers = nil

  CSV.foreach(csv_path, headers: true).with_index(2) do |row, i|
    headers ||= row.headers
    name       = row["name"].to_s.strip
    price_str  = row["price"].to_s
    rating_str = row["rating"].to_s
    link       = (row["link-href"].presence || row["link"].presence)
    image_url  = (row["image-src"].presence || row["image_url"].presence)

    if name.blank?
      skipped += 1
      next
    end

    price  = price_str.gsub(/[^\d\.]/, "").presence&.to_d || 0
    rating = rating_str[/\d+(\.\d+)?/, 0].presence&.to_d

    category = map_csv_category(name, vitamins, protein_supp, digestive_health)

    product =
      if link.present?
        Product.find_or_initialize_by(link: link)
      else
        Product.find_or_initialize_by(name: name, category_id: category.id)
      end

    product.name       ||= name
    product.price        = price
    product.rating       = rating
    product.image_url    = image_url if product.respond_to?(:image_url)
    product.category_id  = category.id

    if product.new_record?
      product.save!
      created += 1
    else
      if product.changed?
        product.save!
        updated += 1
      end
    end

    # Attach image to ActiveStorage if available and not already attached
    if image_url.present? && product.respond_to?(:images) && !product.images.attached?
      begin
        file = URI.open(image_url, open_timeout: 8, read_timeout: 12)
        fname = File.basename(URI(image_url).path.presence || "image.jpg")
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

# =========================
# Products from Walmart API
# =========================
puts "➡️ Importing Walmart API products..."
system('KEYWORDS="ashwagandha,turmeric,lavender oil" LIMIT=90 bin/rake seed:walmart')

# =========================
# Admin user
# =========================
puts "➡️ Seeding admin user..."
admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@prairienaturals.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "prairienaturals")
AdminUser.find_or_create_by!(email: admin_email) do |admin|
  admin.password              = admin_password
  admin.password_confirmation = admin_password
end

# ✅ Only create if there are products & admins to comment on
if AdminUser.any? && Product.any?
  puts "➡️ Creating sample comments..."

  admin = AdminUser.first
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
