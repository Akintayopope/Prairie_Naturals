class CheckoutController < ApplicationController
  before_action :authenticate_user!

  def new
    @order = Order.new(order_params)
    @provinces = ["Manitoba", "Ontario", "Quebec", "Alberta"]

    cart_items = current_user.cart_items.includes(:product)
    @subtotal = cart_items.sum { |item| item.quantity * item.product.price }

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
      # Save order items for tracking
      cart_items.each do |item|
        @order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          unit_price: item.product.price
        )
      end

      # Clear the cart
      cart_items.destroy_all

      # Create Stripe Checkout session
      session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        customer_email: current_user.email,
        line_items: @order.order_items.map do |item|
          {
            price_data: {
              currency: 'cad',
              product_data: {
                name: item.product.name
              },
              unit_amount: (item.unit_price * 100).to_i
            },
            quantity: item.quantity
          }
        end,
        mode: 'payment',
        success_url: checkout_success_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: checkout_cancel_url
      )

      # Save session ID for later tracking
      @order.update(stripe_session_id: session.id)

      redirect_to session.url, allow_other_host: true
    else
      @provinces = ["Manitoba", "Ontario", "Quebec", "Alberta"]
      render :new
    end
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    order = Order.find_by(stripe_session_id: session.id)

    if order && order.status != "paid"
      order.update(status: "paid", stripe_payment_id: session.payment_intent)
    end

    redirect_to order_path(order), notice: "Payment successful!"
  end

  def cancel
    redirect_to orders_path, alert: "Payment was canceled."
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
