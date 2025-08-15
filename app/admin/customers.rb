# app/admin/customers.rb
ActiveAdmin.register User, as: "Customer" do
  menu label: "Customers", parent: "Users", priority: 1

  scope :all
  scope :with_orders, default: true do |users|
    users.joins(:orders).distinct
  end

  filter :email
  filter :username if User.column_names.include?("username")
  filter :orders_created_at, as: :date_range, label: "Order date"

  controller do
    def scoped_collection
      User
        .joins(:orders)
        .select(
          "users.*",
          "COUNT(DISTINCT orders.id) AS orders_count_calc",
          "COALESCE(SUM(orders.tax), 0)   AS lifetime_tax",
          "COALESCE(SUM(orders.total), 0) AS lifetime_total"
        )
        .group("users.id")
    end
  end

  index title: "Customers with Orders" do
    selectable_column
    id_column
    column :email
    column(:username) { |u| u.try(:username) }
    column("Orders")       { |u| number_with_delimiter(u.attributes["orders_count_calc"].to_i) }
    column("Total Tax")    { |u| number_to_currency(u.attributes["lifetime_tax"].to_d) }
    column("Grand Total")  { |u| number_to_currency(u.attributes["lifetime_total"].to_d) }
    actions
  end

  show title: proc { |u| "Customer ##{u.id} — #{u.email}" } do
    attributes_table do
      row :email
      row(:username) { |u| u.try(:username) }
      row("Province") { |u| u.province&.name }
      row("Total Orders") { Order.where(user_id: u.id).count }
      row("Lifetime Tax")   { number_to_currency(Order.where(user_id: u.id).sum(:tax)) }
      row("Lifetime Total") { number_to_currency(Order.where(user_id: u.id).sum(:total)) }
    end

    panel "Orders" do
      orders = resource.orders.includes(order_items: :product).order(created_at: :desc)
      table_for orders do
        column("Order #")   { |o| link_to o.id, admin_order_path(o) rescue o.id }
        column("Placed At") { |o| l(o.created_at, format: :short) }
        column("Products") do |o|
          o.order_items.map { |oi|
            name = (oi.product&.name || oi.product&.title || "Product ##{oi.product_id}")
            "#{name} × #{oi.quantity}"
          }.join(", ").presence || "—"
        end
        column("Tax")   { |o| number_to_currency(o.tax || 0) }
        column("Total") { |o| number_to_currency(o.total || 0) }
      end
    end
  end
end
