class Api::HealthProductsController < ApplicationController
  protect_from_forgery with: :null_session
  require "httparty"
  require "json"

  before_action :extract_params

  def index
    resp =
      HTTParty.get(
        "#{@base}/api/v2/search",
        query: {
          page_size: @limit,
          page: @page,
          categories_tags_en: @tag, # search by English category tag
          fields: FIELDS.join(","),
          locale: @lang
        },
        headers: {
          "User-Agent" => "PrairieNaturals/HealthAPI 1.0",
          "Accept" => "application/json"
        },
        timeout: 20
      )

    body = parse_body(resp)
    products = Array(body["products"])
    payload = products.map { |p| normalize_row(p, @tag) }

    if @debug
      render json: {
               upstream_count: products.size,
               sample_keys: products.first&.keys&.take(12),
               data: payload
             }
    else
      render json: payload
    end
  rescue JSON::ParserError
    render json: {
             error: "Upstream returned non-JSON body"
           },
           status: :bad_gateway
  rescue => e
    Rails.logger.warn("[health_products#index] #{e.class}: #{e.message}")
    render json: { error: e.message }, status: :bad_gateway
  end

  private

  FIELDS = %w[
    product_name
    generic_name
    brands
    categories
    code
    image_front_url
    image_ingredients_url
    image_packaging_url
    image_url
    image_small_url
  ].freeze

  def extract_params
    @source = params[:source].presence_in(%w[obf off]) || "obf"
    @tag = params[:tag].presence || "Shampoos"
    @limit = (params[:limit] || 20).to_i.clamp(1, 100)
    @page = (params[:page] || 1).to_i.clamp(1, 1000)
    @lang = (params[:lang].presence || "en").to_s
    @debug = ActiveModel::Type::Boolean.new.cast(params[:debug])

    @base =
      (
        if @source == "off"
          "https://world.openfoodfacts.org"
        else
          "https://world.openbeautyfacts.org"
        end
      )
  end

  def parse_body(resp)
    raise "Upstream error: #{resp.code}" unless resp.code == 200

    body = resp.parsed_response
    body = JSON.parse(body) if body.is_a?(String)
    raise "Upstream body missing" unless body.is_a?(Hash)

    body
  end

  def normalize_row(p, tag)
    name =
      (
        p["product_name"].to_s.strip.presence ||
          p["generic_name"].to_s.strip.presence || "Untitled"
      )

    desc_bits = []
    if (g = p["generic_name"].to_s.strip).present?
      desc_bits << g
    end
    if (b = p["brands"].to_s.strip).present?
      desc_bits << "Brand: #{b}"
    end
    if (c = p["code"].to_s.strip).present?
      desc_bits << "Barcode: #{c}"
    end

    {
      name: name,
      title: name,
      description:
        (desc_bits.join(" • ").presence || "Health & personal care product"),
      price: price_for(tag),
      stock: rand(8..60),
      category_name: map_bucket(tag),
      images: image_urls(p)
    }
  end

  def map_bucket(tag)
    t = tag.downcase
    if t.include?("vitamin") || t.include?("supplement")
      return "Vitamins & Supplements"
    end
    return "Sports Nutrition" if t.include?("sport")
    if t.include?("shampoo") || t.include?("conditioner") || t.include?("hair")
      return "Hair Care"
    end
    if t.include?("cream") || t.include?("serum") || t.include?("face")
      return "Skin Care"
    end
    return "Oral Care" if t.include?("toothpaste") || t.include?("mouthwash")
    return "Baby Care" if t.include?("baby")
    "Body Care"
  end

  def price_for(tag)
    t = tag.downcase
    range =
      if t.include?("vitamin") || t.include?("supplement")
        (9.99..79.99)
      elsif t.include?("sport")
        (14.99..99.99)
      elsif t.include?("shampoo") || t.include?("hair")
        (5.99..34.99)
      elsif t.include?("toothpaste") || t.include?("oral")
        (3.49..19.99)
      elsif t.include?("cream") || t.include?("serum")
        (7.99..69.99)
      elsif t.include?("baby")
        (3.49..24.99)
      else
        (3.49..29.99)
      end
    rand(range).round(2)
  end

  def image_urls(p)
    %w[
      image_front_url
      image_ingredients_url
      image_packaging_url
      image_url
      image_small_url
    ]
      .map { |k| p[k] }
      .compact
      .select { |u| u.start_with?("http") }
      .uniq
      .first(4)
  end
end
