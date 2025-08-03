# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders = current_user.orders.order(created_at: :desc)
  end

  def show
    @order = current_user.orders.find(params[:id])
    @order_items = @order.order_items.includes(:product)
  end

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
    [["Product", "Quantity", "Unit Price", "Total"]] +
    @order.order_items.map do |item|
      [
        item.product.name,
        item.quantity,
        "$#{'%.2f' % item.unit_price}",
        "$#{'%.2f' % (item.unit_price * item.quantity)}"
      ]
    end,
    header: true,
    width: pdf.bounds.width
  )

  pdf.move_down 20
  pdf.text "Subtotal: $#{'%.2f' % @order.subtotal}"
  pdf.text "Tax: $#{'%.2f' % @order.tax}"
  pdf.text "Total: $#{'%.2f' % @order.total}", style: :bold

  send_data pdf.render,
            filename: "invoice_order_#{@order.id}.pdf",
            type: 'application/pdf',
            disposition: 'inline'
end


end
