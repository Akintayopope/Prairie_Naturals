# lib/tasks/attach_from_folder.rake
namespace :products do
  desc "Attach images from a folder to Products (uploads to CURRENT Active Storage service, e.g., Cloudinary)"
  task attach_from_folder: :environment do
    require "marcel"

    dir = Rails.root.join(ENV["DIR"] || "db/seeds/images")
    abort "Folder not found: #{dir}" unless Dir.exist?(dir)

    current_service = Rails.application.config.active_storage.service.to_s
    abort "Active Storage service not configured" if current_service.blank?

    if defined?(Cloudinary)
      unless Cloudinary.config.cloud_name.present? &&
             Cloudinary.config.api_key.present? &&
             Cloudinary.config.api_secret.present?
        abort "Cloudinary not configured in this environment"
      end
    end

    # Collect files and sort by the first number in the filename (natural sort)
    files = Dir.glob(dir.join("**/*.{jpg,jpeg,png,webp,gif}"), File::FNM_CASEFOLD)
               .sort_by { |p| (File.basename(p)[/\d+/] || "0").to_i }

    match  = (ENV["MATCH"] || "id") # "id" or "index"
    dry    = ENV["DRY_RUN"] == "true"
    purge  = ENV["PURGE_NON_CLOUD"] == "true"
    limit  = (ENV["LIMIT"] || files.length).to_i
    files  = files.first(limit)

    puts "Found #{files.size} file(s) in #{dir} — MATCH=#{match} DRY_RUN=#{dry} PURGE_NON_CLOUD=#{purge}"

    attach = lambda do |product, file|
      if purge
        product.images.attachments.joins(:blob)
               .where.not(active_storage_blobs: { service_name: current_service })
               .find_each { |att| puts "🧹 Purging non-#{current_service} attachment #{att.id}"; att.purge unless dry }
      end

      if dry
        puts "DRY: would attach #{File.basename(file)} → Product ##{product.id} (#{product.name})"
      else
        File.open(file, "rb") do |io|
          product.images.attach(
            io: io,
            filename: File.basename(file),
            content_type: Marcel::MimeType.for(io)
          )
        end
        puts "✅ Attached #{File.basename(file)} → Product ##{product.id} (#{product.name})"
      end
    end

    case match
    when "id"
      files.each do |file|
        id = (File.basename(file)[/\d+/] || "0").to_i
        if id.zero?
          puts "⚠️  No numeric id in #{File.basename(file)} — skipping"
          next
        end
        product = Product.find_by(id: id)
        if product.nil?
          puts "⚠️  No Product with id=#{id} for #{File.basename(file)} — skipping"
          next
        end
        attach.call(product, file)
      end

    when "index"
      # Provide PRODUCT_IDS (comma-separated) or we pick the first N products by id
      ids = (ENV["PRODUCT_IDS"] || "").split(",").map(&:strip).reject(&:empty?).map!(&:to_i)
      products =
        if ids.any?
          Product.where(id: ids).order(:id).to_a
        else
          offset = (ENV["OFFSET"] || 0).to_i
          scope  = Product.all
          if (cid = ENV["CATEGORY_ID"]).present?
            scope = scope.where(category_id: cid)
          end
          scope.order(:id).offset(offset).limit(files.length).to_a
        end

      files.zip(products).each do |file, product|
        if product.nil?
          puts "⚠️  Not enough products for remaining files — stopping"
          break
        end
        attach.call(product, file)
      end

    else
      abort "Unknown MATCH value: #{match.inspect}. Use MATCH=id or MATCH=index."
    end

    puts "Done."
  end
end

