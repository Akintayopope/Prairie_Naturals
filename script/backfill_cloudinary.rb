# script/backfill_cloudinary.rb
require "open-uri"

puts "ActiveStorage service=#{Rails.application.config.active_storage.service}"

fixed = 0
skipped = 0
failed = 0

Product.find_each do |p|
  blobs = p.images.blobs.to_a
  cloud_ok = blobs.any? && blobs.all? { |b| b.service_name == "cloudinary" }

  if cloud_ok
    skipped += 1
    next
  end

  if p.image_url.present?
    begin
      io = URI.open(p.image_url, "User-Agent" => "Mozilla/5.0")
      filename = File.basename(URI.parse(p.image_url).path.presence || "image.jpg")
      p.images.attach(io: io, filename: filename, content_type: "image/jpeg")
      # Purge any non-cloudinary blobs (optional cleanup)
      blobs.reject { |b| b.service_name == "cloudinary" }.each(&:purge_later)
      fixed += 1
      puts "✔ attached to #{p.id} (#{p.name})"
    rescue => e
      failed += 1
      warn "✖ failed for #{p.id}: #{e.message}"
    end
  else
    skipped += 1
  end
end

puts "DONE. fixed=#{fixed} skipped=#{skipped} failed=#{failed}"
