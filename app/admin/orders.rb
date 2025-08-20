ActiveAdmin.register Order do
  includes :user, :address, { order_items: :product }

  permit_params :user_id,
                :address_id,
                :subtotal,
                :tax,
                :total,
                :status,
                :shipping_name,
                :shipping_address,
                :province

  scope :all, default: true
  scope("Pending") { |r| r.where(status: "pending") }
  scope("Paid") { |r| r.where(status: "paid") }
  scope("Processing") { |r| r.where(status: "processing") }
  scope("Shipped") { |r| r.where(status: "shipped") }
  scope("Delivered") { |r| r.where(status: "delivered") }
  scope("Cancelled") { |r| r.where(status: "cancelled") }

  index do
    selectable_column
    id_column

    column("Customer") do |o|
      # Link to the Customer page if you added ActiveAdmin.register User, as: "Customer"
      if defined?(admin_customer_path) && o.user
        link_to(o.user.email, admin_customer_path(o.user))
      else
        o.user&.email || "—"
      end
    end

    column("Address") { |o| o.address&.full_address || "—" }
    column("Items") { |o| o.order_items.sum(:quantity) }
    column(:status) { |o| status_tag o.status }
    column(:subtotal) { |o| number_to_currency(o.subtotal || 0) }
    column(:tax) { |o| number_to_currency(o.tax || 0) }
    column(:total) { |o| number_to_currency(o.total || 0) }
    column :created_at
    actions
  end

  action_item :mark_paid, only: :show, if: -> { resource.status != "paid" } do
    link_to "Mark Paid",
            send(
              "mark_paid_#{ActiveAdmin.application.default_namespace}_order_path",
              resource
            ),
            method: :patch,
            data: {
              turbo: false
            }
  end

  action_item :mark_processing,
              only: :show,
              if: -> { resource.status != "processing" } do
    link_to "Mark Processing",
            send(
              "mark_processing_#{ActiveAdmin.application.default_namespace}_order_path",
              resource
            ),
            method: :patch,
            data: {
              turbo: false
            }
  end

  action_item :mark_shipped,
              only: :show,
              if: -> { resource.status != "shipped" } do
    link_to "Mark Shipped",
            send(
              "mark_shipped_#{ActiveAdmin.application.default_namespace}_order_path",
              resource
            ),
            method: :patch,
            data: {
              turbo: false
            }
  end

  action_item :mark_delivered,
              only: :show,
              if: -> { resource.status != "delivered" } do
    link_to "Mark Delivered",
            send(
              "mark_delivered_#{ActiveAdmin.application.default_namespace}_order_path",
              resource
            ),
            method: :patch,
            data: {
              turbo: false
            }
  end

  action_item :mark_cancelled,
              only: :show,
              if: -> { resource.status != "cancelled" } do
    link_to "Cancel Order",
            send(
              "mark_cancelled_#{ActiveAdmin.application.default_namespace}_order_path",
              resource
            ),
            method: :patch,
            data: {
              turbo: false
            }
  end

  # ---------- Member actions ----------
  member_action :mark_paid, method: :patch do
    resource.update!(status: "paid")
    redirect_to resource_path, notice: "Order marked as Paid."
  end

  member_action :mark_processing, method: :patch do
    resource.update!(status: "processing")
    redirect_to resource_path, notice: "Order marked as Processing."
  end

  member_action :mark_shipped, method: :patch do
    resource.update!(status: "shipped")
    redirect_to resource_path, notice: "Order marked as Shipped."
  end

  member_action :mark_delivered, method: :patch do
    resource.update!(status: "delivered")
    redirect_to resource_path, notice: "Order marked as Delivered."
  end

  member_action :mark_cancelled, method: :patch do
    resource.update!(status: "cancelled")
    redirect_to resource_path, notice: "Order Cancelled."
  end

  # ---------- Batch action ----------
  batch_action :change_status,
               form: -> { { status: Order.statuses } } do |ids, inputs|
    Order.where(id: ids).update_all(
      status: inputs[:status],
      updated_at: Time.current
    )
    redirect_to collection_path,
                notice: "Updated #{ids.size} orders to #{inputs[:status]}."
  end

  # ---------- Filters ----------
  filter :user,
         label: "User (email)",
         as: :select,
         collection: -> { User.order(:email).pluck(:email, :id) }
  filter :status, as: :select, collection: -> { Order.statuses }
  filter :created_at
  filter :total

  # ---------- Form ----------
  form do |f|
    f.semantic_errors
    f.inputs "Order" do
      f.input :user,
              label: "User (email)",
              collection: User.order(:email).pluck(:email, :id)
      f.input :address,
              label: "Address",
              collection:
                Address
                  .includes(:user, :province)
                  .map { |a| ["#{a.user&.email} — #{a.full_address}", a.id] }
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

  # ---------- Show ----------
  show do
    attributes_table do
      row :id
      row("Customer") do |o|
        if defined?(admin_customer_path) && o.user
          link_to(o.user.email, admin_customer_path(o.user))
        else
          o.user&.email || "—"
        end
      end
      row("Address") { |o| o.address&.full_address || "—" }
      row(:status) { status_tag resource.status }
      row(:subtotal) { number_to_currency(resource.subtotal || 0) }
      row(:tax) { number_to_currency(resource.tax || 0) }
      row(:total) { number_to_currency(resource.total || 0) }
      row :shipping_name
      row :shipping_address
      row :province
      row :created_at
      row :updated_at
    end

    panel "Items" do
      items = resource.order_items.includes(:product)
      table_for items do
        column(:product) do |i|
          i.product&.name || i.product&.title || "##{i.product_id}"
        end
        column(:quantity)
        column("Unit Price") do |i|
          unit = i.unit_price || i.product&.price || 0
          number_to_currency(unit)
        end
        column("Line Total") do |i|
          unit = i.unit_price || i.product&.price || 0
          number_to_currency(unit.to_d * i.quantity.to_i)
        end
      end

      # Small summary under the items table
      div class: "mt-2" do
        strong "Items subtotal: "
        items_total =
          items.sum do |i|
            (i.unit_price || i.product&.price || 0).to_d * i.quantity.to_i
          end
        span number_to_currency(items_total)
        text_node " — "
        strong "Order Tax: "
        span number_to_currency(resource.tax || 0)
        text_node " — "
        strong "Order Total: "
        span number_to_currency(resource.total || 0)
      end
    end

    active_admin_comments
  end
end
