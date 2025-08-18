# frozen_string_literal: true

require "httparty"
require "open-uri"
require "action_view"

class WalmartSerpapiImporter
  include HTTParty
  base_uri "https://serpapi.com"

  # Allowed categories (pre-created in DB)
  ALLOWED_CATEGORIES = [
    "Vitamins",
    "Protein Supplements",
    "Digestive Health",
    "Skin Care",
    "Hair Care"
  ].freeze

  CATEGORY_MAP = [
    [/ashwagandha|turmeric|ginseng|supplement|vitamin|capsule|tablet/i, "Vitamins"],
    [/protein|whey|casein|collagen|gainer/i,                           "Protein Supplements"],
    [/digest|probiotic|enzyme|fiber|prebiotic/i,                       "Digestive Health"],
    [/skin|serum|face|cream|lotion|retinol|hyaluronic|sunscreen/i,     "Skin Care"],
    [/hair|shampoo|conditioner|biotin|keratin|scalp/i,                 "Hair Care"]
  ].freeze

  def initialize(api_key: ENV["SERPAPI_KEY"])
    raise "Missing SERPAPI_KEY" if api_key.to_s.strip.empty?
    @api_key   = api_key
    @sanitizer = ActionView::Base.full_sanitizer
  end

  # Import up to +limit+ products for a single keyword using EXACTLY ONE search call (1 credit).
  # Optionally fetch detailed data for the first +enrich_n+ items (each detail = +1 credit).
  #
  # Examples:
  #   import_keyword("ashwagandha", limit: 50)           # 1 credit, up to 50 items
  #   import_keyword("ashwagandha", limit: 50, enrich_n: 2) # 3 credits total
  def import_keyword(keyword, limit: 50, category_name: nil, enrich_n: 0)
    limit    = limit.to_i.clamp(1, 100)      # results per keyword, single call
    enrich_n = enrich_n.to_i.clamp(0, 10)    # keep enrichment tiny

    # ONE SerpAPI call (num = limit, page = 1)
    results = search_walmart!(keyword, page_size: limit)
    return 0 if results.empty?

    imported = 0

    results.first(limit).each_with_index do |r, idx|
      product_id = r["product_id"] || r["us_item_id"] || r["product_id_v2"]
      next unless product_id

      # Only fetch detailed product for first N items to save credits
      pr = idx < enrich_n ? fetch_product!(product_id) : {}

      title = safe_title(pr["title"] || r["title"] || "Untitled")
      next if title.blank?

      desc_html   = pr["short_description_html"] || r["description"] || r["snippet"] || ""
      description = @sanitizer.sanitize(desc_html.to_s)

      # Strict whitelist category
      chosen_category_name =
        category_name.presence ||
        resolve_category(keyword: keyword, serpapi_item: r, title: title)

      unless ALLOWED_CATEGORIES.include?(chosen_category_name)
        raise "Category not allowed: #{chosen_category_name}. Must be one of: #{ALLOWED_CATEGORIES.join(", ")}"
      end
      category = Category.find_by!(name: chosen_category_name)

      # Price, rating, reviews (prefer detailed if present; else from search)
      price_cents  = extract_price_cents(r, pr)
      rating       = extract_rating(r, pr)
      review_count = extract_review_count(r, pr)

      # Image URL — detailed first if enriched, else search thumbnail
      image_url = pick_image_url(pr) ||
                  r["thumbnail"] ||
                  r["image"] ||
                  r.dig("product_page", "image")

      product = Product.find_or_initialize_by(slug: product_id.to_s)

      product.name        = unique_name_for(product, title, product_id)
      product.description = description
      product.category    = category
      product.stock       = 0 if product.respond_to?(:stock=)

      if price_cents
        if product.respond_to?(:price_cents=)
          product.price_cents = price_cents
        elsif product.respond_to?(:price=)
          product.price = price_cents / 100.0
        end
      end

      product.rating       = rating       if rating && product.respond_to?(:rating=)
      product.review_count = review_count if review_count && product.respond_to?(:review_count=)

      product.save!

      if image_url.present? && product.respond_to?(:images) && !product.images.attached?
        attach_first_image(product, image_url, product_id)
      end

      imported += 1
      Rails.logger.info("Imported (#{idx + 1}/#{limit}): #{product.name} → #{category.name}")
    rescue => e
      Rails.logger.warn("Import failed for #{product_id.inspect}: #{e.class} – #{e.message}")
      next
    end

    imported
  end

  # ---------------------- helpers ----------------------

  # EXACTLY ONE API CALL per keyword. No pagination. num = page_size.
  def search_walmart!(keyword, page_size: 50)
    resp = self.class.get("/search.json", query: {
      engine:   "walmart",
      query:    keyword,
      api_key:  @api_key,
      num:      page_size, # up to `limit` items for 1 credit
      page:     1          # do NOT paginate
    }, timeout: 20)

    raise "SerpAPI search HTTP #{resp.code}" unless resp.code == 200
    if (err = resp.parsed_response["error"])
      raise "SerpAPI search error: #{err}"
    end

    Array(resp.parsed_response["organic_results"])
  end

  # Detailed product call (costs +1 credit per call)
  def fetch_product!(product_id)
    resp = self.class.get("/search.json", query: {
      engine:     "walmart_product",
      product_id: product_id,
      api_key:    @api_key
    }, timeout: 20)

    raise "SerpAPI product HTTP #{resp.code}" unless resp.code == 200
    if (err = resp.parsed_response["error"])
      raise "SerpAPI product error: #{err}"
    end

    resp.parsed_response["product_result"] || {}
  end

  def resolve_category(keyword:, serpapi_item:, title:)
    text  = [keyword, serpapi_item["category"], title].compact.join(" ")
    match = CATEGORY_MAP.find { |(rx, _)| rx.match?(text) }
    (match && match.last) || "Vitamins" # safe default within whitelist
  end

  def extract_price_cents(r, pr)
    raw =
      pr.dig("price_map", "price") ||
      pr.dig("price", "raw") ||
      r.dig("primary_offer", "offer_price") ||
      r.dig("primary_offer", "min_price") ||
      r["price"] ||
      r.dig("price", "raw")

    return nil if raw.nil?
    (raw.to_s[/\d+(\.\d+)?/].to_f * 100).round
  end

  def extract_rating(r, pr)
    raw = pr["average_rating"] || r["rating"] || r.dig("product", "rating")
    return nil if raw.nil?
    raw.to_f
  end

  def extract_review_count(r, pr)
    raw = pr["num_reviews"] || r["reviews"] || r.dig("product", "reviews")
    return nil if raw.nil?
    raw.to_i
  end

  def pick_image_url(pr)
    imgs = Array(pr["images"]).compact
    return nil if imgs.empty?

    imgs.each do |im|
      if im.is_a?(String)
        return im if im =~ %r{\Ahttps?://}i
      elsif im.is_a?(Hash)
        return im["large"]     if im["large"].to_s =~ %r{\Ahttps?://}i
        return im["medium"]    if im["medium"].to_s =~ %r{\Ahttps?://}i
        return im["thumbnail"] if im["thumbnail"].to_s =~ %r{\Ahttps?://}i
        return im["link"]      if im["link"].to_s =~ %r{\Ahttps?://}i
        return im["image"]     if im["image"].to_s =~ %r{\Ahttps?://}i
        return im["url"]       if im["url"].to_s =~ %r{\Ahttps?://}i
      end
    end
    nil
  end

  def safe_title(title)
    t = title.to_s.strip
    t = t[0, 200] if t.length > 200
    t
  end

  def unique_name_for(product, title, product_id)
    return title unless Product.where.not(id: product.id).exists?(name: title)
    suffix = " (#{product_id})"
    base   = title[0, [0, 200 - suffix.length].max]
    "#{base}#{suffix}"
  end

  def attach_first_image(product, url, product_id)
    fname = File.basename(URI(url).path.presence || "image.jpg")
    file  = URI.open(url, open_timeout: 8, read_timeout: 15)
    product.images.attach(io: file, filename: fname, content_type: "image/jpeg")
  rescue => e
    Rails.logger.warn("Image attach failed for #{product_id}: #{e.class} – #{e.message}")
  end
end
