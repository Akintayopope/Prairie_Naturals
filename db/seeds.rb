# db/seeds.rb
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

# =====================================
# Categories (baseline seed – optional)
# =====================================
puts "➡️ Ensuring baseline categories exist..."
%w[Hair Skin Vitamins Supplements Body].each do |name|
  Category.find_or_create_by!(name: name)
end

# ==========================================
# Product import from CSV (your scraped file)
# ==========================================
csv_path = Rails.root.join("db/data/iherb_products.csv")
if File.exist?(csv_path)
  puts "➡️ Importing products from #{csv_path} ..."
  created = updated = skipped = 0

  # Single category (CSV has none)
  supplements = Category.find_or_create_by!(name: "Supplements")

  # Helpers
  def to_price(v)  = v.to_s.gsub(/[^\d\.]/, "").presence&.to_d
  def to_rating(v) = v.to_s[/\d+(\.\d+)?/, 0].presence&.to_d

  ActiveRecord::Base.transaction do
    CSV.foreach(csv_path, headers: true).with_index(2) do |row, i|
      begin
        name      = row["name"].to_s.strip
        link      = (row["link-href"].presence || row["link"].presence).to_s.strip
        price     = to_price(row["price"]) || 0.to_d
        rating    = to_rating(row["rating"])
        image_url = row["image-src"].presence

        if name.blank?
          skipped += 1
          next
        end

        attrs = {
          price:     price,
          rating:    rating,
          image_url: image_url,
          link:      link,
          category:  supplements
        }

        # Prefer stable upsert key by link when available; otherwise (name + category)
        product =
          if link.present?
            Product.find_or_initialize_by(link: link)
          else
            Product.find_or_initialize_by(name: name, category_id: supplements.id)
          end

        # Ensure name present for link-keyed records
        product.name ||= name

        if product.new_record?
          product.assign_attributes(attrs)
          product.save!
          created += 1
        else
          if attrs.any? { |k, v| product.public_send(k) != v }
            product.update!(attrs)
            updated += 1
          end
        end
      rescue => e
        puts "❌ Row #{i} (#{row['name']}) failed: #{e.class} – #{e.message}"
      end
    end
  end

  puts "✅ Products import done. Created: #{created}, Updated: #{updated}, Skipped blank-name rows: #{skipped}"
else
  puts "⚠️ No CSV found at #{csv_path}. Skipping product import."
  puts "   Tip: Save your scrape to db/data/iherb_products.csv and re-run: rails db:seed"
end

# ==================
# Admin user (dev)
# ==================
puts "➡️ Seeding admin user..."
admin_email    = ENV.fetch("ADMIN_EMAIL", "admin@prairienaturals.com")
admin_password = ENV.fetch("ADMIN_PASSWORD", "prairienaturals")

AdminUser.find_or_create_by!(email: admin_email) do |admin|
  admin.password              = admin_password
  admin.password_confirmation = admin_password
end

puts "✅ Seeding completed!"
