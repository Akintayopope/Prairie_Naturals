# lib/tasks/active_storage_migrate.rake
namespace :active_storage do
  desc "Copy blobs from non-current services to the CURRENT service (e.g., Cloudinary)"
  task copy_to_current: :environment do
    require "stringio"

    current = Rails.application.config.active_storage.service.to_s
    abort "Active Storage service not configured" if current.blank?

    # Optional filters/env
    from_services = (ENV["FROM"] || "").split(",").map(&:strip).reject(&:empty?)
    dry           = ENV["DRY_RUN"] == "true"
    batch_size    = (ENV["BATCH"] || 100).to_i

    scope = ActiveStorage::Blob.where.not(service_name: current)
    scope = scope.where(service_name: from_services) if from_services.any?

    total = scope.count
    puts "Migrating #{total} blob(s) to :#{current} (dry=#{dry}, from=#{from_services.presence || 'ANY'}) ..."

    migrated = failed = 0
    scope.find_each(batch_size: batch_size) do |blob|
      begin
        if dry
          puts "DRY: would migrate blob ##{blob.id} (#{blob.filename}, #{blob.byte_size} bytes) from :#{blob.service_name} -> :#{current}"
          next
        end

        # Stream from the source service
        blob.open do |io|
          new_key = ActiveStorage::Blob.generate_unique_secure_token
          ActiveStorage::Blob.service.upload(
            new_key, io,
            checksum: blob.checksum,
            content_type: blob.content_type,
            filename: blob.filename
          )
          # Point the existing blob to the new file/service
          blob.update_columns(key: new_key, service_name: current, updated_at: Time.current)
        end

        migrated += 1
        puts "✓ blob ##{blob.id} (#{blob.filename}) -> :#{current}"
      rescue => e
        failed += 1
        warn "!! blob ##{blob.id} failed: #{e.class} #{e.message}"
      end
    end

    puts "Done. Migrated=#{migrated}, Failed=#{failed}, Remaining=#{ActiveStorage::Blob.where.not(service_name: current).count}"
  end

  desc "List counts by service for Product images"
  task counts: :environment do
    counts = ActiveStorage::Attachment.joins(:blob)
             .where(record_type: "Product", name: "images")
             .group("active_storage_blobs.service_name")
             .count
    puts counts.inspect
  end
end
