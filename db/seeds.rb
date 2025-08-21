require "csv"
require "open-uri"

puts "Seeding database..."

# ---------------------------
# Provinces (idempotent)
# ---------------------------
puts "Seeding provinces..."
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
  { name: "Saskatchewan",              pst: 0.06,    gst: 0.05, hst: 0.00 },
  { name: "Yukon",                     gst: 0.05,    pst: 0.00,  hst: 0.00 },
  { name: "Northwest Territories",     gst: 0.05,    pst: 0.00,  hst: 0.00 },
  { name: "Nunavut",                   gst: 0.05,    pst: 0.00,  hst: 0.00 },
].each do |prov|
  Province.find_or_create_by!(name: prov[:name]) do |p|
    p.pst = prov[:pst]
    p.gst = prov[:gst]
    p.hst = prov[:hst]
  end
end

StaticPage.find_or_create_by!(slug: "about")   { |p| p.title = "About";   p.body = "Write about your store here." }
StaticPage.find_or_create_by!(slug: "contact") { |p| p.title = "Contact"; p.body = "Email: support@prairienatural.com\nAddress: …" }

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
puts "Creating categories..."
%w[Vitamins Protein\ Supplements Digestive\ Health Skin\ Care Hair\ Care].each do |name|
  Category.find_or_create_by!(name: name)
end

# ---------------------------
# Helpers (defined BEFORE use)
# ---------------------------
def attach_remote_image!(record, url)
  return false if url.blank?
  fname = File.basename(URI(url).path.presence || "image.jpg")
  URI.open(url, open_timeout: 8, read_timeout: 12) do |io|
    if record.respond_to?(:image)
      record.image.attach(io: io, filename: fname, content_type: io.content_type)
    elsif record.respond_to?(:images)
      record.images.attach(io: io, filename: fname, content_type: io.content_type)
    end
  end
  true
rescue => e
  Rails.logger.warn("Image attach failed for #{record.class}##{record.id}: #{e.class} #{e.message}")
  false
end

def attach_local_image!(record, path)
  return false if path.blank? || !File.exist?(path)
  fname = File.basename(path)
  File.open(path, "rb") do |io|
    if record.respond_to?(:image)
      record.image.attach(io: io, filename: fname)
    elsif record.respond_to?(:images)
      record.images.attach(io: io, filename: fname)
    end
  end
  true
rescue => e
  Rails.logger.warn("Local image attach failed for #{record.class}##{record.id}: #{e.class} #{e.message}")
  false
end

def product_has_image?(p)
  (p.respond_to?(:image)  && p.image.attached?) ||
  (p.respond_to?(:images) && p.images.attached?)
end

def product_price_value(p)
  p.respond_to?(:price_cents) ? p.price_cents.to_i : (p.price || 0).to_f
end

def set_price!(p, amount)
  amt = amount.to_d
  if p.respond_to?(:price_cents)
    p.price_cents = (amt * 100).to_i
  else
    p.price = amt
  end
end

# ---------------------------
# Custom Products (Hair Care from local images)
# ---------------------------
puts "Seeding Hair Care custom products from local files…"
hair_care = Category.find_or_create_by!(name: "Hair Care")

images_dir = Rails.root.join("db/seeds/images")   # put your 10 files here as image_1.jpg ... image_10.jpg
files = Dir[images_dir.join("image_*.{png,jpg,jpeg,webp}")].
          sort_by { |p| File.basename(p)[/\d+/].to_i }.
          first(10)

names = [
  "Argan Oil Shampoo",
  "Keratin Repair Conditioner",
  "Biotin Growth Serum",
  "Rosemary Scalp Oil",
  "Castor Oil Hair Mask",
  "Coconut Hydration Shampoo",
  "Tea Tree Anti-Dandruff Shampoo",
  "Volumizing Hair Spray",
  "Color Protect Conditioner",
  "Daily Nourish Hair Cream"
]

descriptions = [
  "Infused with Moroccan argan oil to restore shine and moisture.",
  "Deep repair formula with keratin proteins for damaged hair.",
  "Biotin-rich serum that promotes thicker, fuller-looking hair.",
  "Rosemary essential oil blend to refresh the scalp and stimulate roots.",
  "Castor oil mask to strengthen and deeply condition dry strands.",
  "Lightweight coconut-based shampoo that hydrates without buildup.",
  "Soothing tea tree formula to reduce flakes and itchiness.",
  "Strong-hold spray that boosts volume and locks in style.",
  "Color-protecting conditioner that shields against fading.",
  "Everyday nourishing cream that softens and prevents split ends."
]

prices  = [19.99,22.50,29.00,15.99,18.75,25.00,21.50,20.25,16.50,23.99]
ratings = [4.6,4.7,4.8,4.5,4.4,4.9,4.3,4.6,4.2,4.7]
reviews = [186,142,95,88,76,132,73,54,61,120]

created = updated = kept = dropped = 0

files.each_with_index do |filepath, i|
  name   = names[i]        || "Hair Care Product #{i + 1}"
  desc   = descriptions[i] || "A quality hair care product."
  price  = prices[i]       || 9.99
  rating = ratings[i]      || 4.5
  rcnt   = reviews[i]      || 10

  product = Product.find_or_initialize_by(name: name, category_id: hair_care.id)
  product.category_id       = hair_care.id
  set_price!(product, price)
  product.rating            = rating if product.respond_to?(:rating)
  product.review_count      = rcnt   if product.respond_to?(:review_count)
  product.description       = desc   if product.respond_to?(:description)
  product.short_description = desc   if product.respond_to?(:short_description) && product.short_description.blank?

  # Save if new or changed
  to_create = product.new_record?
  before_changes = product.changes.dup
  product.save! if to_create || product.changed?
  created += 1 if to_create
  updated += 1 if !to_create && before_changes.any?

  attach_local_image!(product, filepath) unless product_has_image?(product)

  # enforce rule: must have price > 0 and at least one image
  has_img = product_has_image?(product)
  price_v = product_price_value(product)
  if !has_img || price_v <= 0
    product.destroy
    dropped += 1
  else
    kept += 1
  end
end

puts "Hair Care custom products — Files: #{files.size}, Created: #{created}, Updated: #{updated}, Kept: #{kept}, Dropped: #{dropped}"

# ---------------------------
# Products from CSV
# ---------------------------
puts "Importing products from CSV..."
csv_path = Rails.root.join("db/data/iherb_products.csv")
if !File.exist?(csv_path)
  puts "CSV not found at #{csv_path}"
else
  created = updated = skipped = kept = dropped = 0
  headers = nil

  CSV.foreach(csv_path, headers: true).with_index(2) do |row, i|
    headers        ||= row.headers
    name             = row["name"].to_s.strip.presence || row["title"].to_s.strip
    price_str        = row["price"].to_s
    rating_str       = row["rating"].to_s
    link             = (row["link-href"].presence || row["link"].presence)
    image_url        = (row["image-src"].presence || row["image_url"].presence)
    csv_category     = row["category"].to_s.strip

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

    product.name           ||= name[0, 200]
    if product.respond_to?(:price_cents)
      product.price_cents     = (price * 100).to_i
    else
      product.price           = price
    end
    product.rating           = (rating_value if rating_value&.positive?)
    product.review_count     = review_count if review_count
    product.image_url        = image_url if product.respond_to?(:image_url)
    product.category_id      = category.id

    to_create = product.new_record?
    before_changes = product.changes.dup
    product.save! if to_create || product.changed?
    created += 1 if to_create
    updated += 1 if !to_create && before_changes.any?

    if image_url.present? && !product_has_image?(product)
      attach_remote_image!(product, image_url)
    end

    has_img   = product_has_image?(product)
    price_val = product_price_value(product)
    if !has_img || price_val <= 0
      product.destroy
      dropped += 1
    else
      kept += 1
    end
  rescue => e
    puts "Row #{i} failed (headers: #{headers.inspect}): #{e.class} – #{e.message}"
  end

  puts "CSV import done. Created: #{created}, Updated: #{updated}, Skipped rows: #{skipped}, Kept: #{kept}, Dropped(no image/price): #{dropped}"
end

# ---------------------------
# Walmart API (inline)
# ---------------------------
puts "Importing Walmart API products..."
begin
  require Rails.root.join("app/services/walmart_serpapi_importer")
  importer = WalmartSerpapiImporter.new
  keywords = ["ashwagandha", "turmeric", "lavender oil"]
  limit    = 90

  prev_adapter = ActiveJob::Base.queue_adapter
  ActiveJob::Base.queue_adapter = :inline

  keywords.each_with_index do |kw, idx|
    puts "[#{idx + 1}/#{keywords.size}] Importing #{limit} items for: '#{kw}'"
    count = importer.import_keyword(kw, limit: limit)
    puts "   → Imported #{count} items for '#{kw}'"
    puts
  end
ensure
  ActiveJob::Base.queue_adapter = prev_adapter
end

# ---------------------------
# Final cleanup & report
# ---------------------------
puts "Final cleanup: dropping any product left without image or price..."
removed = 0
Product.find_each do |p|
  price_val = product_price_value(p)
  unless product_has_image?(p) && price_val > 0
    p.destroy
    removed += 1
  end
end
puts "Removed #{removed} post-import stragglers."

puts "Import Summary by Category:"
%w[Vitamins Protein\ Supplements Digestive\ Health Skin\ Care Hair\ Care].each do |cat|
  c = Category.find_by(name: cat)
  puts "   #{cat}: #{c&.products&.count || 0} products"
end

puts "Seeding admin user..."
admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@prairienaturals.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "prairienaturals")

AdminUser.find_or_create_by!(email: admin_email) do |admin|
  admin.password              = admin_password
  admin.password_confirmation = admin_password
end

if AdminUser.any? && Product.any?
  puts "Creating sample comments..."
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
  puts "Added 5 sample comments."
else
  puts "No AdminUser or Product found — skipping comment seeding."
end

puts "Seeding completed!"
