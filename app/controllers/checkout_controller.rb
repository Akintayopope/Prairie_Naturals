class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def new
    @order = Order.new(order_params)
    @provinces = ["Manitoba", "Ontario", "Quebec", "Alberta"]

    cart_items = current_user.cart_items.includes(:product)
    @subtotal = cart_items.sum { |item| item.quantity * item.product.price }

    # Calculate tax and total if a province is selected
    if @order.province.present?
      @tax_rate = tax_rate_for(@order.province)
      @tax = @subtotal * @tax_rate
      @total = @subtotal + @tax
    else
      @tax = nil
      @total = nil
    end
  end

  def create
    @order = current_user.orders.build(order_params)
    cart_items = current_user.cart_items.includes(:product)

    # Calculate amounts
    subtotal = cart_items.sum { |item| item.quantity * item.product.price }
    tax_rate = tax_rate_for(@order.province)
    tax_amount = subtotal * tax_rate
    total = subtotal + tax_amount

    @order.subtotal = subtotal
    @order.tax = tax_amount
    @order.total = total

    if @order.save
      cart_items.each do |item|
        @order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          unit_price: item.product.price
        )
      end

      cart_items.destroy_all
      redirect_to order_path(@order), notice: "Order placed successfully!"
    else
      @provinces = ["Manitoba", "Ontario", "Quebec", "Alberta"]
      render :new
    end
  end

  private

  def order_params
    params.fetch(:order, {}).permit(:shipping_name, :shipping_address, :province)
  end

  def tax_rate_for(province)
    {
      "Manitoba" => 0.12,
      "Ontario" => 0.13,
      "Quebec" => 0.14975,
      "Alberta" => 0.05
    }[province] || 0
  end
end
