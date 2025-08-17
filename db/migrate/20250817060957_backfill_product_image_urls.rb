# db/migrate/XXXXXXXXXXXX_backfill_product_image_urls.rb
class BackfillProductImageUrls < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Backfilling products.image_url from CSV/API (fallback: blob URLs)" do
      require "csv"

      # Load external image URLs from CSV in repo if present
      csv_map = {}
      csv_path = Rails.root.join("db/data/iherb_products.csv")
      if File.exist?(csv_path)
        CSV.read(csv_path, headers: true).each do |row|
          name      = row["name"].presence || row["title"].presence
          image_url = row["image_url"].presence || row["image-src"].presence
          link_href = row["link-href"].presence || row["link"].presence
          next if name.blank?
          csv_map[[:name, name]] = image_url if image_url.present?
          csv_map[[:link, link_href]] = image_url if link_href.present? && image_url.present?
        end
      end

      # Host for rails_blob_url (fallback path)
      host = ENV["APP_HOST"].presence || "localhost"
      Rails.application.routes.default_url_options[:host] = host
      Rails.application.routes.default_url_options[:protocol] = "https"

      updated = 0

      Product.includes(images_attachments: :blob).find_in_batches(batch_size: 500) do |batch|
        batch.each do |p|
          next if p.image_url.present?

          # A) Prefer CSV/API by name
          if (url = csv_map[[:name, p.name]])
            p.update_columns(image_url: url)
            updated += 1
            next
          end

          # B) CSV/API by link (if your model has a 'link' column)
          if p.respond_to?(:link) && p.link.present?
            if (url = csv_map[[:link, p.link]])
              p.update_columns(image_url: url)
              updated += 1
              next
            end
          end

          # C) Fallback to existing attachment URL (works until attachments are wiped)
          if p.images.attached?
            begin
              blob_url = Rails.application.routes.url_helpers.rails_blob_url(p.images.first)
              p.update_columns(image_url: blob_url)
              updated += 1
            rescue => e
              Rails.logger.warn "Blob URL backfill failed for Product##{p.id}: #{e.class} - #{e.message}"
            end
          end
        end
      end

      updated
    end
  end

  def down
    # no-op
  end
end
