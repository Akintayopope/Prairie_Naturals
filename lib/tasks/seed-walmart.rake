# lib/tasks/seed_walmart.rake
require Rails.root.join("app/services/walmart_serpapi_importer.rb")

namespace :seed do
  desc "Import products via SerpApi Walmart. Args: KEYWORDS=comma,list LIMIT=30"
  task walmart: :environment do
    # Keywords mapped to your 5 categories
    keywords = (ENV["KEYWORDS"] || "ashwagandha,turmeric,lavender essential oil,hair growth serum,protein powder")
               .split(",").map(&:strip)
    limit = (ENV["LIMIT"] || 30).to_i

    puts "🚀 Starting Walmart API import..."
    puts "📋 Keywords: #{keywords.join(', ')}"
    puts "🔢 Limit per keyword: #{limit}"
    puts "🗂️  Available categories: #{WalmartSerpapiImporter::ALLOWED_CATEGORIES.join(', ')}"
    puts

    importer = WalmartSerpapiImporter.new

    keywords.each_with_index do |keyword, index|
      puts "➡️  [#{index + 1}/#{keywords.length}] Importing #{limit} items for: '#{keyword}'"

      begin
        # Let the service map keywords to categories automatically
        importer.import_keyword(keyword, limit: limit)
      rescue => e
        puts "❌ Failed to import keyword '#{keyword}': #{e.message}"
        puts e.backtrace.first(3)
      end

      puts # blank line for readability
    end

    # Summary
    puts "📊 Import Summary:"
    WalmartSerpapiImporter::ALLOWED_CATEGORIES.each do |cat_name|
      category = Category.find_by(name: cat_name)
      count = category&.products&.count || 0
      puts "   #{cat_name}: #{count} products"
    end

    puts "🎯 Walmart import completed!"
  end
end
