# app/services/walmart_serpapi_importer.rb
require "httparty"
require "open-uri"
require "action_view"

class WalmartSerpapiImporter
  ALLOWED_CATEGORIES = [
    "Vitamins & Supplements",
    "Sports Nutrition",
    "Skin Care",
    "Hair Care",
    "Oral Care",
    "Body Care",
    "Baby Care"
  ].freeze

  # Keyword → allowed category mapping (extend as you like)
  CATEGORY_MAP = {
    /ashwagandha|turmeric|milk thistle|echinacea|ginseng|moringa|collagen|probiotic|vitamin|zinc|magnesium/i => "Vitamins & Supplements",
    /lavender|tea tree|rosehip|aloe|witch hazel|argan|jojoba|shea|serum|moisturizer|cleanser|toner/i         => "Skin Care",
    /shampoo|conditioner|biotin hair|hair oil|scalp/i                                                       => "Hair Care",
    /toothpaste|mouthwash|oral/i                                                                             => "Oral Care",
    /body wash|lotion|soap|deodorant|massage oil/i                                                           => "Body Care",
    /baby|infant|newborn|diaper|nappy|baby lotion|baby shampoo/i                                             => "Baby Care",
    /protein|creatine|pre[-\s]?workout|electrolyte|bcaa/i                                                    => "Sports Nutrition"
  }.freeze

  def map_keyword_to_allowed_category(keyword, fallback: "Vitamins & Supplements")
    key = keyword.to_s
    CATEGORY_MAP.each do |regex, cat|
      return cat if key.match?(regex)
    end
    fallback
  end

  include HTTParty
  base_uri "https://serpapi.com"

  def initialize(api_key: ENV["SERPAPI_KEY"])
    raise "Missing SERPAPI_KEY" if api_key.to_s.strip.empty?
    @api_key = api_key
  end

  def unique_name!(base_title, product_id, current_slug)
  base = base_title.to_s.strip
  # If another product already uses this exact name (not this slug), suffix and keep trying
  name = base
  n = 1

  while Product.where("LOWER(name) = ?", name.downcase)
               .where.not(slug: current_slug)
               .exists?
    # First try: "Title (123456)"; subsequent: "Title (123456) #2", "#3", ...
    core = "#{base} (#{product_id})"
    name = n == 1 ? core : "#{core} ##{n}"
    n += 1
  end

  name
end


  def import_keyword(keyword, limit: 30, category_name: nil)
    # 1) Search Walmart
    search = self.class.get("/search.json", query: {
      engine: "walmart",
      query:  keyword,
      api_key: @api_key
    })

    results = Array(search.parsed_response["organic_results"])
    picks   = results.first(limit) || []

    # 2) Pick a category that passes your validation
    mapped_name =
      if category_name.present? && ALLOWED_CATEGORIES.include?(category_name)
        category_name
      else
        map_keyword_to_allowed_category(keyword)
      end
    category = Category.find_or_create_by!(name: mapped_name)

    # 3) Hydrate each product and attach a clean image
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
      images = Array(pr["images"]).compact

      product = Product.find_or_initialize_by(slug: product_id.to_s)
      product.update!(
  name: unique_name!(title, product_id, product.slug),
  description: desc,
  price: price.to_f,
  stock: 0,
  category: category
)


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
