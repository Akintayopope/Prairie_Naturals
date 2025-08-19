# app/admin/customers.rb
if ActiveRecord::Base.connection.data_source_exists?("users")
  ActiveAdmin.register User, as: "Customer" do
    menu label: "Customers", parent: "Users", priority: 1

    # ----- Strong params (allow admin to set password) -----
    permit_params :email, :username, :first_name, :last_name, :phone,
                  :address1, :address2, :city, :postal_code, :country,
                  :province_id, :notes,
                  :password, :password_confirmation,
                  tags: [], images: [],
                  addresses_attributes: [ :id, :line1, :line2, :city, :province_id, :postal_code, :country, :_destroy ]

    # ----- Scopes -----
    scope :all, default: true
    scope :with_orders do |users|
      users.joins(:orders).distinct
    end

    # ----- Filters -----
    filter :email
    filter :username if User.column_names.include?("username")
    filter :orders_created_at, as: :date_range, label: "Order date"

    # ----- Controller customizations -----
    controller do
      # Show users without orders too (for "All")
      def scoped_collection
        User
          .left_outer_joins(:orders)
          .select(
            "users.*",
            "COUNT(DISTINCT orders.id) AS orders_count_calc",
            "COALESCE(SUM(orders.tax), 0)   AS lifetime_tax",
            "COALESCE(SUM(orders.total), 0) AS lifetime_total"
          )
          .group("users.id")
          .includes(:province)
      end

      # On CREATE: if admin leaves password blank, auto-generate a temp one
      # and send reset instructions (Devise Recoverable).
      def create
        if params[:user].present?
          if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
            temp = SecureRandom.base58(12)
            params[:user][:password] = temp
            params[:user][:password_confirmation] = temp
            @send_reset_after_create = true
          end
        end

        super do |success, failure|
          success.html do
            if @send_reset_after_create && resource.respond_to?(:send_reset_password_instructions)
              resource.send_reset_password_instructions
              flash[:notice] = "Customer created. Reset password email sent to #{resource.email}."
            else
              flash[:notice] ||= "Customer created."
            end
            redirect_to resource_path(resource) # path-only → safe redirect
          end
        end
      end

      # On UPDATE: if password fields are blank, don't touch the password.
      def update
        if params[:user].present?
          if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
            params[:user].delete(:password)
            params[:user].delete(:password_confirmation)
          end
        end

        super do |success, failure|
          success.html do
            flash[:notice] ||= "Customer updated."
            redirect_to resource_path(resource) # path-only → safe redirect
          end
        end
      end
    end

# Quick action to send reset email anytime
# inside ActiveAdmin.register User, as: "Customer" do

action_item :reset_password, only: :show do
  if resource.respond_to?(:send_reset_password_instructions)
    path = url_for([ :reset_password, :admin, resource ]) rescue "#{resource_path(resource)}/reset_password"
    link_to "Send Reset Password Email", path, data: { turbo_method: :post }
  end
end

member_action :reset_password, method: :post do
  if resource.respond_to?(:send_reset_password_instructions)
    resource.send_reset_password_instructions
    redirect_to resource_path(resource), notice: "Reset password instructions sent to #{resource.email}."
  else
    redirect_to resource_path(resource), alert: "Reset password is not enabled for this model."
  end
end


    # ----- Index -----
    index title: "Customers" do
      selectable_column
      id_column
      column :email
      column(:username) { |u| u.try(:username) }
      column("Province")     { |u| u.province&.name }
      column("Orders")       { |u| number_with_delimiter(u.attributes["orders_count_calc"].to_i) }
      column("Total Tax")    { |u| number_to_currency(u.attributes["lifetime_tax"].to_d) }
      column("Grand Total")  { |u| number_to_currency(u.attributes["lifetime_total"].to_d) }
      actions
    end

    # ----- Show -----
    show title: proc { |u| "Customer ##{u.id} — #{u.email}" } do
      attributes_table do
        row :email
        row(:username)      { |u| u.try(:username) }
        row("Province")     { |u| u.province&.name }
        row("Total Orders") { |u| u.orders.count }
        row("Lifetime Tax") { |u| number_to_currency(u.orders.sum(:tax) || 0) }
        row("Lifetime Total") { |u| number_to_currency(u.orders.sum(:total) || 0) }
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

    # ----- Form (admin can set/change password) -----
    form do |f|
      f.semantic_errors
      f.inputs "Customer" do
        f.input :email
        f.input :username if User.column_names.include?("username")
        f.input :first_name if User.column_names.include?("first_name")
        f.input :last_name  if User.column_names.include?("last_name")
        f.input :phone      if User.column_names.include?("phone")

        f.input :address1   if User.column_names.include?("address1")
        f.input :address2   if User.column_names.include?("address2")
        f.input :city       if User.column_names.include?("city")
        if User.column_names.include?("province_id") && ActiveRecord::Base.connection.data_source_exists?("provinces")
          f.input :province, as: :select, collection: Province.order(:name).pluck(:name, :id), include_blank: true
        end
        f.input :postal_code if User.column_names.include?("postal_code")
        f.input :country     if User.column_names.include?("country")
        f.input :notes       if User.column_names.include?("notes")

        # Admin can set or change password here.
        # Leaving these blank on edit will NOT change the password (handled in controller#update).
        f.input :password
        f.input :password_confirmation
      end
      f.actions
    end

    # Optional: CSV export
    csv do
      column(:id)
      column(:email)
      column(:username) { |u| u.try(:username) }
      column(:province) { |u| u.province&.name }
      column("orders_count")    { |u| u.attributes["orders_count_calc"].to_i }
      column("lifetime_tax")    { |u| u.attributes["lifetime_tax"].to_d }
      column("lifetime_total")  { |u| u.attributes["lifetime_total"].to_d }
      column(:created_at)
      column(:updated_at)
    end
  end
end
