# db/seeds/products_with_images.rb
require "open-uri"

def attach_image!(record, url, filename: nil, content_type: "image/jpeg")
  record.images.attach(
    io: URI.open(url),
    filename: filename || File.basename(URI.parse(url).path.presence || "image.jpg"),
    content_type: content_type
  )
end

hair = Category.find_or_create_by!(name: "Hair Care")

p1 = Product.find_or_initialize_by(name: "Argan Oil Shampoo")
p1.category ||= hair
p1.price_cents ||= 1299
p1.description ||= "Nourishing daily shampoo"
p1.save!
attach_image!(p1, "https://res.cloudinary.com/<your_cloud_name>/image/upload/vXXXXXXXX/sample1.jpg") if p1.images.blank?

p2 = Product.find_or_initialize_by(name: "Coconut Conditioner")
p2.category ||= hair
p2.price_cents ||= 1499
p2.description ||= "Hydrating conditioner"
p2.save!
attach_image!(p2, "https://res.cloudinary.com/<your_cloud_name>/image/upload/vXXXXXXXX/sample2.jpg") if p2.images.blank?

puts "Seeded. totals => products: #{Product.count}, attachments: #{ActiveStorage::Attachment.count}, blobs: #{ActiveStorage::Blob.count}"
