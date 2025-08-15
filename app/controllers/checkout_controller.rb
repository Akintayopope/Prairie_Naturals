# app/controllers/checkout_controller.rb
class CheckoutController < ApplicationController
  before_action :authenticate_user!
  before_action :set_provinces, only: [ :new, :create ]

  # GET /checkout/new
  # Renders the preview page. Province selection updates totals live (via GET).
  def new
    if current_user.cart_items.none?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    # Transient order used for previewing totals (not saved here)
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
  # Persists the order, creates line items, starts Stripe Checkout.
  def create
    if params[:order_id].present?
    order = current_user.orders.includes(order_items: :product).find_by(id: params[:order_id])
    return redirect_to orders_path, alert: "Order not found." unless order
    return redirect_to order_path(order), notice: "This order is already paid." if order.status == "paid"

    # Build Stripe line items from the order snapshot
    line_items = order.order_items.map do |item|
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
      line_items << {
        price_data: {
          currency: "cad",
          product_data: { name: "Tax" },
          unit_amount: tax_cents
        },
        quantity: 1
      }
    end

    stripe_session = Stripe::Checkout::Session.create(
      payment_method_types: [ "card" ],
      customer_email: current_user.email,
      line_items: line_items,
      mode: "payment",
      success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
      cancel_url:  cancel_checkout_url
    )

    order.update!(stripe_session_id: stripe_session.id)
    return redirect_to stripe_session.url, allow_other_host: true
    end

  # --- existing cart checkout flow continues below ---
  cart_items = current_user.cart_items.includes(:product)
  return redirect_to(cart_path, alert: "Your cart is empty.") if cart_items.none?

    cart_items = current_user.cart_items.includes(:product)
    return redirect_to(cart_path, alert: "Your cart is empty.") if cart_items.none?

    @order = current_user.orders.build(order_params)
    return prepare_failed_new(cart_items, "Please choose a province.") if @order.province.blank?

    province_record = Province.find_by(name: @order.province)
    return prepare_failed_new(cart_items, "Please choose a valid province.") unless province_record

    # Extract address-only params (Order does not have these columns)
    city        = address_params[:city]
    postal_code = address_params[:postal_code]

    # Upsert the user's shipping address
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

      # Snapshot monetary fields on the order
      @order.subtotal = subtotal
      @order.tax      = tax_amount
      @order.total    = total

      @order.save!

      # Snapshot each cart line into order_items
      cart_items.find_each do |i|
        @order.order_items.create!(
          product:    i.product,
          quantity:   i.quantity,
          unit_price: i.product.price # snapshot at purchase time
        )
      end
      cart_items.destroy_all

      # Build Stripe line items (products + a separate Tax line)
      line_items = @order.order_items.map do |item|
        {
          price_data: {
            currency: "cad",
            product_data: { name: item.product.name },
            unit_amount: to_cents(item.unit_price)
          },
          quantity: item.quantity
        }
      end

      tax_cents = to_cents(@order.tax)
      if tax_cents > 0
        line_items << {
          price_data: {
            currency: "cad",
            product_data: { name: "Tax" },
            unit_amount: tax_cents
          },
          quantity: 1
        }
      end

      stripe_session = Stripe::Checkout::Session.create(
        payment_method_types: [ "card" ],
        customer_email: current_user.email,
        line_items: line_items,
        mode: "payment",
        success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url:  cancel_checkout_url
      )

      @order.update!(stripe_session_id: stripe_session.id)
      redirect_to stripe_session.url, allow_other_host: true and return
    end
  rescue ActiveRecord::RecordInvalid => e
    prepare_failed_new(current_user.cart_items.includes(:product), "Validation error: #{e.record.errors.full_messages.to_sentence}")
  rescue Stripe::StripeError => e
    prepare_failed_new(current_user.cart_items.includes(:product), "Payment error: #{e.message}")
  end

  # GET /checkout/success
  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    order   = Order.find_by(stripe_session_id: session.id)
    if order && order.status != "paid"
      order.update(status: "paid", stripe_payment_id: session.payment_intent)
    end
    redirect_to order_path(order), notice: "Payment successful!"
  end

  # GET /checkout/cancel
  def cancel
    redirect_to orders_path, alert: "Payment was canceled."
  end

  # GET /checkout/preview_receipt.pdf
  # Generates a pro-forma PDF based on current cart + entered fields.
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

  # Use DB as source of truth for the dropdown (records, not strings)
  def set_provinces
    @provinces = Province.order(:name)
  end

  # Only allow Order's real columns here
  def order_params
    params.fetch(:order, {}).permit(:shipping_name, :shipping_address, :province)
  end

  # Address-only fields (NOT Order columns)
  def address_params
    params.require(:order).permit(:city, :postal_code)
  end

  # Combine GST/PST/HST; handle nils safely
  def tax_rate_for(province_name)
    p = Province.find_by(name: province_name)
    return 0.to_d unless p
    p.hst.to_d + p.gst.to_d + p.pst.to_d
  end

  # Convert a decimal dollar amount to integer cents (rounded)
  def to_cents(amount)
    ((amount.to_d * 100).round).to_i
  end

  # Re-render :new with preserved context and message
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
end
