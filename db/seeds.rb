# db/seeds.rb
require "csv"
require "open-uri"
require "mime/types"

puts "🌱 Seeding database..."

# -----------------------------------------------------------------------------
# Image helpers (used by both CSV and API imports)
# -----------------------------------------------------------------------------
def sanitized_filename_from(url, fallback: "image.jpg")
  uri = URI.parse(url)
  name = File.basename(uri.path.presence || fallback)
  name = "image.jpg" if name.blank? || name == "/" || name.include?("?")
  ext  = File.extname(name).downcase
  name += ".jpg" if ext.blank?
  name
rescue
  fallback
end

def detect_content_type(url)
  ext = File.extname(URI.parse(url).path).downcase rescue ""
  return "image/jpeg" if [".jpg", ".jpeg"].include?(ext)
  return "image/png"  if ext == ".png"
  return "image/webp" if ext == ".webp"
  MIME::Types.type_for(ext).first&.content_type || "image/jpeg"
end

def attach_remote_image!(record, url)
  return if url.blank?
  return unless record.respond_to?(:images)
  return if record.images.attached?

  URI.open(url, open_timeout: 8, read_timeout: 12) do |io|
    fname = sanitized_filename_from(url)
    ctype = detect_content_type(url)
    record.images.attach(io: io, filename: fname, content_type: ctype)
  end

  puts "✅ Image attached for: #{record.try(:name) || record.id}"
rescue => e
  warn "⚠️ Image failed for: #{record.try(:name) || record.id} – #{e.class}: #{e.message}"
  record.update_column(:image_url, url) if record.respond_to?(:image_url) && record.persisted?
end

# ===============================
# Provinces (idempotent upserts)
# ===============================
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
  created = updated = skipped = 0
  headers = nil

  CSV.foreach(csv_path, headers: true).with_index(2) do |row, i|
    headers    ||= row.headers
    name         = row["name"].to_s.strip.presence || row["title"].to_s.strip
    price_str    = row["price"].to_s
    rating_str   = row["rating"].to_s
    link         = (row["link-href"].presence || row["link"].presence)
    image_url    = (row["image-src"].presence || row["image_url"].presence)
    csv_category = row["category"].to_s.strip

    if name.blank?
      skipped += 1
      next
    end

    # --- Price ---
    price = price_str.gsub(/[^\d\.]/, "").presence&.to_d || 0

    # --- Rating + Review Count ---
    rating_value = rating_str[/\A\s*([\d.]+)/, 1]&.to_f
    review_count = rating_str[/-\s*([\d,]+)\s+Reviews/i, 1]&.delete(",")&.to_i

    # --- Category ---
    category =
      if csv_category.present?
        Category.find_or_create_by!(name: csv_category)
      else
        # Keeps your existing mapping logic (assumes these exist in your codebase)
        map_csv_category(name, vitamins, protein_supp, digestive_health)
      end

    # --- Find or init the product ---
    product =
      if link.present?
        Product.find_or_initialize_by(link: link)
      else
        Product.find_or_initialize_by(name: name, category_id: category.id)
      end

    # --- Assign attributes ---
    product.name        ||= name
    product.price         = price
    product.rating        = (rating_value if rating_value&.positive?)
    product.review_count  = review_count if review_count
    product.image_url     = image_url if product.respond_to?(:image_url)
    product.category_id   = category.id

    # Save if new or changed
    if product.new_record? || product.changed?
      product.save!
      product.new_record? ? created += 1 : updated += 1
    end

    # --- Attach image (updated helper used here) ---
    attach_remote_image!(product, image_url)

  rescue => e
    puts "❌ Row #{i} failed (headers: #{headers.inspect}): #{e.class} – #{e.message}"
  end

  puts "✅ CSV import done. Created: #{created}, Updated: #{updated}, Skipped: #{skipped}"
end

# =========================
# Products from Walmart API
# =========================
puts "➡️ Importing Walmart API products..."
# Keep your existing task; inside that task, call `attach_remote_image!(product, image_url)`
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
