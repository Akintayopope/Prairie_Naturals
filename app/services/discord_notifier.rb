require "net/http"
require "uri"
require "json"

class DiscordNotifier
  class << self
    def order_created(order)
      return unless enabled?
      post(message_for_created(order))
    end

    def order_paid(order)
      return unless enabled?
      post(message_for_paid(order))
    end

    private

    def enabled?
      webhook_url.present? &&
        %w[on true 1 yes].include?(ENV["DISCORD_NOTIFICATIONS"].to_s.downcase)
    end

    def webhook_url
      ENV["DISCORD_WEBHOOK_URL"].to_s.strip
    end

    # Build messages -----------------------------------------------------------

    def message_for_created(order)
      [
        "📦 **New order** ##{order.id}",
        "🛍️ #{items_summary(order)}",
        "👤 #{customer_label(order)}",
        "💵 #{money(order.total)}"
      ].join(" • ")
    end

    def message_for_paid(order)
      [
        "✅ **Order paid** ##{order.id}",
        "🛍️ #{items_summary(order)}",
        "💵 #{money(order.total)}"
      ].join(" • ")
    end

    def items_summary(order)
      items =
        order
          .order_items
          .includes(:product)
          .map do |oi|
            name =
              (
                oi.product&.name || oi.product&.title ||
                  "Product ##{oi.product_id}"
              ).to_s.strip
            name = truncate(name, 70)
            qty = (oi.quantity || 1).to_i
            "#{name} x#{qty}"
          end

      return "No items" if items.empty?

      max = 4
      if items.length > max
        "#{items.first(max).join(" • ")} • +#{items.length - max} more"
      else
        items.join(" • ")
      end
    end

    def customer_label(order)
      order.user&.username.presence || order.user&.email.presence || "customer"
    end

    def money(number)
      sprintf("$%.2f", number.to_d)
    end

    def truncate(text, max_len)
      return text if text.length <= max_len
      text[0, max_len - 1] + "…"
    end

    def post(content)
      uri = URI.parse(webhook_url)
      # Ask Discord to return the created message JSON (useful while testing)
      uri.query = [uri.query, "wait=true"].compact.join("&")

      req = Net::HTTP::Post.new(uri)
      req["Content-Type"] = "application/json"
      req.body = { content: content }.to_json

      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: (uri.scheme == "https")
      ) do |http|
        res = http.request(req)

        Rails.logger.info(
          "[DiscordNotifier] status=#{res.code} body=#{res.body.to_s[0, 160]}"
        )
        res
      end
    rescue => e
      Rails.logger.error("[DiscordNotifier] #{e.class}: #{e.message}")
      nil
    end
  end
end
