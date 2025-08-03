ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { "Admin Dashboard" }

  content title: proc { "Welcome, Admin" } do
    columns do
      column do
        panel "📦 Recent Orders" do
          table_for Order.order(created_at: :desc).limit(5) do
            column("Order #")     { |order| link_to order.id, admin_order_path(order) }
            column("Customer")    { |order| order.user.email }
           column("Status") { |order| status_tag(order.status.titleize, class: order.status) }

            column("Total")       { |order| number_to_currency(order.total) }
            column("Date")        { |order| order.created_at.strftime("%b %d, %Y") }
          end
        end
      end

      column do
        panel "📊 Quick Stats" do
          para "🧾 Total Orders: #{Order.count}"
          para "💰 Total Revenue: #{number_to_currency(Order.sum(:total))}"
          para "🛒 Orders This Month: #{Order.where(created_at: Time.current.beginning_of_month..Time.current).count}"
          para "👥 Total Users: #{User.count}"
          para "📦 Products in Stock: #{Product.sum(:stock)}"
        end
      end
    end

    columns do
      column do
        panel "🆕 Recently Added Products" do
          table_for Product.order(created_at: :desc).limit(5) do
            column("Name")        { |product| link_to product.name, admin_product_path(product) }
            column("Category")    { |product| product.category.name rescue "N/A" }
            column("Price")       { |product| number_to_currency(product.price) }
            column("Stock")       { |product| product.stock }
          end
        end
      end

      column do
        panel "📁 Quick Admin Actions" do
          ul do
            li link_to "View All Orders", admin_orders_path
            li link_to "Manage Products", admin_products_path
            li link_to "Manage Users", admin_users_path
            li link_to "Manage Categories", admin_categories_path
            li link_to "Manage Coupons", admin_coupons_path
            li link_to "Create New Product", new_admin_product_path
          end
        end
      end
    end
  end
end
