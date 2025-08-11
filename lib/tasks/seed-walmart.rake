# lib/tasks/seed-walmart.rake
require Rails.root.join("app/services/walmart_serpapi_importer.rb")

namespace :seed do
  desc "Import herbal categories via SerpApi Walmart. Args: KEYWORDS=comma,list LIMIT=30"
  task walmart: :environment do
    keywords = (ENV["KEYWORDS"] || "ashwagandha,turmeric,lavender oil")
               .split(",").map(&:strip)
    limit = (ENV["LIMIT"] || 30).to_i

    importer = WalmartSerpapiImporter.new
    keywords.each do |kw|
      puts "➡️  Importing #{limit} items for: #{kw}"
      importer.import_keyword(kw, limit: limit, category_name: kw.titleize)
    end

    puts "🎯 Done."
  end
end
