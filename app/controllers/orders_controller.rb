# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!

  # GET /orders
  def index
    @orders = current_user.orders
                          .includes(order_items: :product, address: :province)
                          .order(created_at: :desc)
  end

  # GET /orders/:id
  def show
    @order = current_user.orders
                         .includes(order_items: :product, address: :province)
                         .find(params[:id])
  end

  # GET /orders/new
  def new
    @order = current_user.orders.new
  end

  # POST /orders
  def create
    @order = current_user.orders.new(order_params)

    if @order.save
      # ✅ custom flash type (success) — make sure ApplicationController has:
      #   add_flash_types :success, :warning, :info
      flash[:success] = "Order placed successfully. 🎉"
      redirect_to @order
    else
      # stays on the form and shows validation errors
      flash.now[:warning] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  # GET /orders/:id/invoice
  def invoice
    @order = current_user.orders.find(params[:id])

    pdf = Prawn::Document.new
    logo_path = Rails.root.join("app/assets/images/logo.png")

    pdf.image logo_path, height: 50 if File.exist?(logo_path)
    pdf.move_down 20

    pdf.text "Invoice", size: 24, style: :bold, align: :center
    pdf.move_down 10
    pdf.text "Order ##{@order.id}", size: 16
    pdf.text "Date: #{@order.created_at.strftime('%B %d, %Y')}"
    pdf.text "Status: #{@order.status.titleize}"
    pdf.move_down 10

    pdf.text "Shipping Address:"
    pdf.text "#{@order.shipping_name}"
    pdf.text "#{@order.shipping_address}"
    pdf.move_down 20

    pdf.text "Order Details", style: :bold
    pdf.table(
      [ [ "Product", "Quantity", "Unit Price", "Total" ] ] +
      @order.order_items.map do |item|
        [
          item.product.name,
          item.quantity,
          "$#{format('%.2f', item.unit_price)}",
          "$#{format('%.2f', (item.unit_price * item.quantity))}"
        ]
      end,
      header: true,
      width: pdf.bounds.width
    )

    pdf.move_down 20
    pdf.text "Subtotal: $#{format('%.2f', @order.subtotal)}"
    pdf.text "Tax: $#{format('%.2f', @order.tax)}"
    pdf.text "Total: $#{format('%.2f', @order.total)}", style: :bold

    send_data pdf.render,
              filename: "invoice_order_#{@order.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  # Adjust to match your Order schema. Extra keys are harmless if not present.
  def order_params
    params.require(:order).permit(
      :shipping_name, :shipping_address, :billing_address, :province_id,
      :postal_code, :phone, :status,
      # If you use nested items or address:
      order_items_attributes: %i[id product_id quantity unit_price _destroy],
      address_attributes: %i[id line1 line2 city province_id postal_code _destroy]
    )
  end
end
