ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "📊 Dashboard"

  content title: "Prairie Naturals Admin Dashboard" do
    # Welcome Message
    div class: "welcome-message" do
      para "👋 Welcome back, #{current_admin_user.email}!"
    end

    # Top Metrics (Responsive Cards)
    div class: "top-metrics-wrapper" do
      div class: "top-metrics" do
        div class: "metric-card bg-indigo" do
          h3 "🛒 Total Orders"
          h2 Order.count
        end
        div class: "metric-card bg-green" do
          h3 "💰 Total Revenue"
          h2 number_to_currency(Order.sum(:total))
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

# Recent Orders Table
panel "🧾 Recent Orders" do
  table_for Order.order(created_at: :desc).limit(5) do
    column("Order #")    { |order| link_to order.id, admin_order_path(order) }
    column("Customer")   { |order| order.user&.email || "N/A" }

    column("Status") do |order|
  status_class = case order.status.to_s.downcase
  when "paid" then "ok"
  when "cancelled", "failed", "0" then "error"
  else "warning"
  end
  status_tag(order.status.titleize, class: status_class)
end


    column("Total")      { |order| number_to_currency(order.total) }
    column("Date")       { |order| order.created_at.strftime("%b %d, %Y") }
  end
end

    # Charts Section
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

    # Recent Products Table
    panel "🆕 Recently Added Products" do
      table_for Product.order(created_at: :desc).limit(5) do
        column("Name") { |p| link_to p.name, admin_product_path(p) }
        column("Category") { |p| p.category&.name || "Uncategorized" }
        column("Price") { |p| number_to_currency(p.price) }
        column("Stock Left") do |p|
          stock = p.stock || 0
          css_class = stock > 10 ? "ok" : stock > 0 ? "warning" : "error"
          status_tag("#{stock}", class: css_class)
        end
      end
    end
  end
end
