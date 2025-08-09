# frozen_string_literal: true
require "httparty"
require "open-uri"
require "action_view" # for HTML -> text sanitizing

class WalmartSerpapiImporter
  include HTTParty
  base_uri "https://serpapi.com"

  def initialize(api_key: ENV["SERPAPI_KEY"])
    raise "Missing SERPAPI_KEY" if api_key.to_s.strip.empty?
    @api_key = api_key
  end

  # Import N products for one keyword (e.g., "ashwagandha")
  def import_keyword(keyword, limit: 30, category_name: nil)
    # 1) search Walmart
    search = self.class.get("/search.json", query: {
      engine: "walmart",
      query:  keyword,
      api_key: @api_key
    })

    results = Array(search.parsed_response["organic_results"])
    picks   = results.first(limit) || []

    # 2) make/find category
    category = Category.find_or_create_by!(name: category_name || keyword.to_s.titleize)

    # 3) loop results → fetch full product details (for clean images)
    picks.each do |r|
      product_id = r["product_id"] || r["us_item_id"]
      next unless product_id

      details = self.class.get("/search.json", query: {
        engine:     "walmart_product",
        product_id: product_id,
        api_key:    @api_key
      })

      pr = details.parsed_response["product_result"] || {}

      title = pr["title"] || r["title"] || "Untitled"
      desc_html = pr["short_description_html"] || r["description"] || ""
      desc = ActionView::Base.full_sanitizer.sanitize(desc_html.to_s)

      price = pr.dig("price_map", "price") ||
              r.dig("primary_offer", "offer_price") || 0

      images = Array(pr["images"]).compact # array of image URLs

      # use product_id as stable identifier to avoid duplicates
      product = Product.find_or_initialize_by(slug: product_id.to_s)
      product.update!(
        name: title,
        description: desc,
        price: price.to_f,
        stock: 0,
        category: category
      )

      # attach the first image if none attached yet
      if images.any? && !product.images.attached?
        begin
          url  = images.first
          file = URI.open(url, open_timeout: 8, read_timeout: 12)
          fname = File.basename(URI(url).path.presence || "image.jpg")
          product.images.attach(io: file, filename: fname)
        rescue => e
          Rails.logger.warn("Image attach failed for #{product_id}: #{e.message}")
        end
      end
    end
  end
end
