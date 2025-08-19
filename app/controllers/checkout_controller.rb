# app/controllers/checkout_controller.rb
class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provinces, only: [ :new, :create ]

  class << self
    def action_methods
      super + Set.new(%w[success])
    end
  end # <-- This was missing!

  # GET /checkout/new
  def new
    if current_user.cart_items.none?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    @order      = Order.new(order_params)
    @cart_items = current_user.cart_items.includes(:product)
    @orders     = current_user.orders.order(created_at: :desc).limit(5)

    @subtotal = @cart_items.sum { |i| i.quantity * i.product.price }

    if @order.province.present?
      @tax_rate = tax_rate_for(@order.province)
      @tax      = @subtotal * @tax_rate
      @total    = @subtotal + @tax
    else
      @tax = @total = nil
    end
  end

  # POST /checkout
  # If params[:order_id] exists, pay that existing order.
  # Otherwise, build a new order from the cart and pay it.
  def create
    unless Stripe.api_key.present?
      redirect_to cart_path, alert: "Payments unavailable (missing Stripe key)." and return
    end

    if params[:order_id].present?
      order = current_user.orders.includes(order_items: :product).find_by(id: params[:order_id])
      return redirect_to orders_path, alert: "Order not found." unless order
      return redirect_to order_path(order), notice: "This order is already paid." if order.status == "paid"

      stripe_session = create_checkout_session_for(order)
      order.update!(stripe_session_id: stripe_session.id)
      return redirect_to stripe_session.url, allow_other_host: true
    end

    # --- Create a brand-new order from the cart ---
    cart_items = current_user.cart_items.includes(:product)
    return redirect_to(cart_path, alert: "Your cart is empty.") if cart_items.none?

    @order = current_user.orders.build(order_params)
    return prepare_failed_new(cart_items, "Please choose a province.") if @order.province.blank?

    province_record = Province.find_by(name: @order.province)
    return prepare_failed_new(cart_items, "Please choose a valid province.") unless province_record

    city        = address_params[:city]
    postal_code = address_params[:postal_code]

    address = current_user.address || current_user.build_address
    address.assign_attributes(
      line1:       @order.shipping_address,
      city:        city,
      postal_code: postal_code,
      province_id: province_record.id
    )
    address.name = @order.shipping_name if address.respond_to?(:name=)

    ActiveRecord::Base.transaction do
      address.save!

      @order.address  = address
      @order.status ||= "pending"

      subtotal   = cart_items.sum { |i| i.quantity * i.product.price }
      tax_rate   = tax_rate_for(@order.province)
      tax_amount = subtotal * tax_rate
      total      = subtotal + tax_amount

      @order.subtotal = subtotal
      @order.tax      = tax_amount
      @order.total    = total
      @order.save!

      cart_items.find_each do |i|
        @order.order_items.create!(
          product:    i.product,
          quantity:   i.quantity,
          unit_price: i.product.price # snapshot price
        )
      end
      cart_items.destroy_all

      stripe_session = create_checkout_session_for(@order)
      @order.update!(stripe_session_id: stripe_session.id)
      redirect_to stripe_session.url, allow_other_host: true and return
    end
  rescue ActiveRecord::RecordInvalid => e
    prepare_failed_new(current_user.cart_items.includes(:product), "Validation error: #{e.record.errors.full_messages.to_sentence}")
  rescue Stripe::StripeError => e
    prepare_failed_new(current_user.cart_items.includes(:product), "Payment error: #{e.message}")
  end

  # POST /orders/:id/pay
  # Resume payment for an existing order
  def pay
    unless Stripe.api_key.present?
      redirect_to orders_path, alert: "Payments unavailable (missing Stripe key)." and return
    end

    order = current_user.orders.includes(order_items: :product).find_by(id: params[:id])
    return redirect_to orders_path, alert: "Order not found." unless order
    return redirect_to order_path(order), notice: "This order is already paid." if order.status == "paid"

    stripe_session = create_checkout_session_for(order)
    order.update!(stripe_session_id: stripe_session.id)
    redirect_to stripe_session.url, allow_other_host: true
  rescue Stripe::StripeError => e
    redirect_to order_path(order), alert: "Payment error: #{e.message}"
  end

  # GET /checkout/success
  def success
    if params[:session_id].blank?
      redirect_to orders_path, alert: "Missing payment session." and return
      @order ||= current_user.orders.where(status: :paid).order(created_at: :desc).first
      redirect_to(@order ? order_path(@order) : orders_path, notice: "Payment successful")

    end

    s = Stripe::Checkout::Session.retrieve(params[:session_id])
    order = Order.find_by(id: s.metadata["order_id"]) ||
            Order.find_by(stripe_session_id: s.id)

    unless order
      redirect_to orders_path, alert: "Order not found for this payment." and return
    end

    if order.status != "paid" && s.payment_status == "paid"
      order.update!(
        status: "paid",
        stripe_payment_id: s.payment_intent # e.g. "pi_..."
      )
    end

    redirect_to order_path(order), notice: "Payment successful!"
  end

  # GET /checkout/cancel
  def cancel
    redirect_to orders_path, alert: "Payment was canceled."
  end

  # GET /checkout/preview_receipt.pdf
  def preview_receipt
    cart_items = current_user.cart_items.includes(:product)
    return redirect_to(new_checkout_path, alert: "Your cart is empty.") if cart_items.none?

    shipping_name    = params.dig(:order, :shipping_name).to_s
    shipping_address = params.dig(:order, :shipping_address).to_s
    city             = params.dig(:order, :city).to_s
    postal_code      = params.dig(:order, :postal_code).to_s
    province_name    = params.dig(:order, :province).to_s

    subtotal = cart_items.sum { |i| i.quantity * i.product.price }
    tax_rate = tax_rate_for(province_name)
    tax      = subtotal * tax_rate
    total    = subtotal + tax

    pdf = Prawn::Document.new
    pdf.text "Order Preview (Pro-forma)", size: 22, style: :bold
    pdf.move_down 8
    pdf.text "Date: #{Time.zone.now.strftime("%B %d, %Y")}"
    pdf.text "Customer: #{shipping_name.presence || current_user.email}"
    ship_to = [ shipping_address, city, province_name, postal_code ].reject(&:blank?).join(", ")
    pdf.text "Ship To: #{ship_to}"
    pdf.move_down 10
    pdf.text "Items", style: :bold
    pdf.move_down 4
    cart_items.each do |item|
      line_total = item.quantity * item.product.price
      pdf.text "#{item.product.name}  x#{item.quantity} — #{sprintf("$%.2f", line_total)}"
    end
    pdf.move_down 10
    pdf.text "Subtotal: #{sprintf("$%.2f", subtotal)}"
    pdf.text "Tax (#{(tax_rate * 100).round(2)}%): #{sprintf("$%.2f", tax)}"
    pdf.text "Total: #{sprintf("$%.2f", total)}", style: :bold
    pdf.move_down 10
    pdf.text "Note: This is a preview/quote. Final receipt is issued after successful payment.", size: 9, style: :italic

    send_data pdf.render,
              filename: "order-preview-#{Time.zone.now.to_i}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  private

  def set_provinces
    @provinces = Province.order(:name)
  end

  # Only Order's real columns
  def order_params
    params.fetch(:order, {}).permit(:shipping_name, :shipping_address, :province)
  end

  # address-only (NOT Order columns)
  def address_params
    params.require(:order).permit(:city, :postal_code)
  end

  # Combine GST/PST/HST; handle nils
  def tax_rate_for(province_name)
    p = Province.find_by(name: province_name)
    return 0.to_d unless p
    p.hst.to_d + p.gst.to_d + p.pst.to_d
  end

  # dollars -> integer cents
  def to_cents(amount)
    ((amount.to_d * 100).round).to_i
  end

  # rerender :new with context + error
  def prepare_failed_new(cart_items, message = nil)
    @cart_items = cart_items
    @orders     = current_user.orders.order(created_at: :desc).limit(5)
    @order    ||= Order.new(order_params)
    @subtotal   = @cart_items.sum { |i| i.quantity * i.product.price }
    if @order&.province.present?
      @tax_rate = tax_rate_for(@order.province)
      @tax      = @subtotal * @tax_rate
      @total    = @subtotal + @tax
    end
    flash.now[:alert] = message if message.present?
    render :new, status: :unprocessable_entity
  end

  # Build Stripe Checkout line items from an order snapshot, incl. Tax line.
  def build_line_items_from_order(order)
    items = order.order_items.map do |item|
      {
        price_data: {
          currency: "cad",
          product_data: { name: item.product&.name || "Product ##{item.product_id}" },
          unit_amount: to_cents(item.unit_price)
        },
        quantity: item.quantity
      }
    end

    tax_cents = to_cents(order.tax || 0)
    if tax_cents > 0
      items << {
        price_data: {
          currency: "cad",
          product_data: { name: "Tax" },
          unit_amount: tax_cents
        },
        quantity: 1
      }
    end

    items
  end

  # Create a Stripe Checkout Session for an existing order (snapshot).
  def create_checkout_session_for(order)
    Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      customer_email: current_user.email,
      line_items: build_line_items_from_order(order),
      mode: "payment",
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url:  cancel_checkout_url,
      metadata: { order_id: order.id }
    )
  end
end
