# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "📊 Dashboard"

  content title: "Prairie Naturals Admin Dashboard" do
    # ------------------ Welcome ------------------
    div class: "welcome-message" do
      para "👋 Welcome back, #{current_admin_user.email}!"
    end

    # ------------------ Top Metrics ------------------
    div class: "top-metrics-wrapper" do
      div class: "top-metrics" do
        div class: "metric-card bg-indigo" do
          h3 "🛒 Total Orders"
          h2 Order.count
        end
        div class: "metric-card bg-green" do
          h3 "💰 Total Revenue"
          h2 number_to_currency(Order.sum(:total) || 0)
        end
        div class: "metric-card bg-yellow" do
          h3 "📅 This Month's Orders"
          h2 Order.where(created_at: Time.current.beginning_of_month..Time.current).count
        end
        div class: "metric-card bg-blue" do
          h3 "👤 Total Users"
          h2 User.count
        end
      end
    end

    # ------------------ Recent Orders ------------------
    panel "🧾 Recent Orders" do
      table_for Order.order(created_at: :desc).limit(5) do
        # Use auto_link so links work regardless of namespace (:internal, :admin, etc.)
        column("Order #") { |o| auto_link(o, o.id) }
        column("Customer") { |o| o.user ? auto_link(o.user, o.user.email) : "N/A" }

        column("Status") do |o|
          status_class = case o.status.to_s.downcase
                         when "paid" then "ok"
                         when "cancelled", "failed", "0" then "error"
                         else "warning"
                         end
          status_tag(o.status.to_s.titleize, class: status_class)
        end

        column("Total") { |o| number_to_currency(o.total || 0) }
        column("Date")  { |o| l(o.created_at, format: :short) }
      end

      # Namespace-aware "View all" button (works for :internal or any future rename)
      ns = ActiveAdmin.application.default_namespace # e.g., :internal
      index_helper = "#{ns}_orders_path"
      if helpers.respond_to?(index_helper)
        div { link_to "View all orders", send(index_helper), class: "button" }
      end
    end

    # ------------------ Charts ------------------
    columns do
      column do
        panel "📈 Orders This Month" do
          render partial: "admin/dashboard/orders_chart"
        end
      end
      column do
        panel "💵 Revenue This Month" do
          render partial: "admin/dashboard/revenue_chart"
        end
      end
    end

    # ------------------ Recent Products ------------------
    panel "🆕 Recently Added Products" do
      table_for Product.order(created_at: :desc).limit(5) do
        column("Name")      { |p| auto_link(p, p.name) }
        column("Category")  { |p| p.try(:category).try(:name) || "Uncategorized" }
        column("Price")     { |p| number_to_currency(p.price || 0) }
        column("Stock Left") do |p|
          stock = (p.respond_to?(:stock) && p.stock) ? p.stock.to_i : 0
          css_class = stock > 10 ? "ok" : stock > 0 ? "warning" : "error"
          status_tag(stock.to_s, class: css_class)
        end
      end

      # Namespace-aware "View all" for products
      ns = ActiveAdmin.application.default_namespace
      index_helper = "#{ns}_products_path"
      if helpers.respond_to?(index_helper)
        div { link_to "View all products", send(index_helper), class: "button" }
      end
    end
  end
end
