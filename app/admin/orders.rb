# app/admin/orders.rb
ActiveAdmin.register Order do
  includes :user, :address, order_items: :product

  permit_params :user_id, :address_id, :subtotal, :tax, :total,
                :status, :shipping_name, :shipping_address, :province

  # Nice scopes for quick filtering
  scope :all, default: true
  scope("Pending")    { |r| r.where(status: "pending") }
  scope("Paid")       { |r| r.where(status: "paid") }
  scope("Processing") { |r| r.where(status: "processing") }
  scope("Shipped")    { |r| r.where(status: "shipped") }
  scope("Delivered")  { |r| r.where(status: "delivered") }
  scope("Cancelled")  { |r| r.where(status: "cancelled") }

  index do
    selectable_column
    id_column
    column("User")    { |o| o.user&.email }
    column("Address") { |o| o.address&.full_address }
    column(:status)   { |o| status_tag o.status }
    column(:subtotal) { |o| number_to_currency(o.subtotal) }
    column(:tax)      { |o| number_to_currency(o.tax) }
    column(:total)    { |o| number_to_currency(o.total) }
    column :created_at
    actions
  end

  # -------- One-click status changes on the show page (namespace-agnostic) --------
  ns = ActiveAdmin.application.default_namespace # e.g., :internal

  action_item :mark_paid, only: :show, if: -> { resource.status != "paid" } do
    link_to "Mark Paid",
            send("mark_paid_#{ActiveAdmin.application.default_namespace}_order_path", resource),
            method: :patch, data: { turbo: false }
  end

  action_item :mark_processing, only: :show, if: -> { resource.status != "processing" } do
    link_to "Mark Processing",
            send("mark_processing_#{ActiveAdmin.application.default_namespace}_order_path", resource),
            method: :patch, data: { turbo: false }
  end

  action_item :mark_shipped, only: :show, if: -> { resource.status != "shipped" } do
    link_to "Mark Shipped",
            send("mark_shipped_#{ActiveAdmin.application.default_namespace}_order_path", resource),
            method: :patch, data: { turbo: false }
  end

  action_item :mark_delivered, only: :show, if: -> { resource.status != "delivered" } do
    link_to "Mark Delivered",
            send("mark_delivered_#{ActiveAdmin.application.default_namespace}_order_path", resource),
            method: :patch, data: { turbo: false }
  end

  action_item :mark_cancelled, only: :show, if: -> { resource.status != "cancelled" } do
    link_to "Cancel Order",
            send("mark_cancelled_#{ActiveAdmin.application.default_namespace}_order_path", resource),
            method: :patch, data: { turbo: false }
  end

  # -------- Member actions (unchanged) --------
  member_action :mark_paid,       method: :patch do
    resource.update!(status: "paid")
    redirect_to resource_path, notice: "Order marked as Paid."
  end

  member_action :mark_processing, method: :patch do
    resource.update!(status: "processing")
    redirect_to resource_path, notice: "Order marked as Processing."
  end

  member_action :mark_shipped,    method: :patch do
    resource.update!(status: "shipped")
    redirect_to resource_path, notice: "Order marked as Shipped."
  end

  member_action :mark_delivered,  method: :patch do
    resource.update!(status: "delivered")
    redirect_to resource_path, notice: "Order marked as Delivered."
  end

  member_action :mark_cancelled,  method: :patch do
    resource.update!(status: "cancelled")
    redirect_to resource_path, notice: "Order Cancelled."
  end

  # Batch update status for many orders at once
  batch_action :change_status, form: -> { { status: Order.statuses } } do |ids, inputs|
    Order.where(id: ids).update_all(status: inputs[:status], updated_at: Time.current)
    redirect_to collection_path, notice: "Updated #{ids.size} orders to #{inputs[:status]}."
  end

  filter :user,  label: "User (email)", as: :select,
         collection: -> { User.order(:email).pluck(:email, :id) }
  filter :status, as: :select, collection: -> { Order.statuses }
  filter :created_at
  filter :total

  form do |f|
    f.semantic_errors
    f.inputs "Order" do
      f.input :user, label: "User (email)", collection: User.order(:email).pluck(:email, :id)
      f.input :address, label: "Address",
              collection: Address.includes(:user, :province).map { |a| ["#{a.user&.email} — #{a.full_address}", a.id] }
      f.input :status, as: :select, collection: Order.statuses
      f.input :subtotal
      f.input :tax
      f.input :total
      f.input :shipping_name
      f.input :shipping_address
      f.input :province
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row("User")    { |o| o.user&.email }
      row("Address") { |o| o.address&.full_address }
      row(:status)   { status_tag resource.status }
      row(:subtotal) { number_to_currency(resource.subtotal) }
      row(:tax)      { number_to_currency(resource.tax) }
      row(:total)    { number_to_currency(resource.total) }
      row :shipping_name
      row :shipping_address
      row :province
      row :created_at
      row :updated_at
    end

    panel "Items" do
      table_for resource.order_items do
        column(:product)     { |i| i.product&.name || "##{i.product_id}" }
        column(:quantity)
        column("Unit Price") { |i| number_to_currency(i.unit_price) }
        column("Line Total") { |i| number_to_currency(i.unit_price * i.quantity) }
      end
    end

    active_admin_comments
  end
end
