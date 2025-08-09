class CheckoutController < ApplicationController
  before_action :authenticate_user!

  PROVINCES = [
    "Manitoba","Ontario","Quebec","Alberta","Saskatchewan","British Columbia",
    "Nova Scotia","New Brunswick","Prince Edward Island","Newfoundland and Labrador"
  ].freeze

  def new
    if current_user.cart_items.none?
      redirect_to cart_path, alert: "Your cart is empty." and return
    end

    @order      = Order.new(order_params)
    @provinces  = PROVINCES
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

  def create
    cart_items = current_user.cart_items.includes(:product)
    return redirect_to(cart_path, alert: "Your cart is empty.") if cart_items.none?

    @order = current_user.orders.build(order_params)
    return prepare_failed_new(cart_items, "Please choose a province.") if @order.province.blank?

    province_record = Province.find_by(name: @order.province)
    return prepare_failed_new(cart_items, "Please choose a valid province.") unless province_record

   city        = params.dig(:order, :city)
postal_code = params.dig(:order, :postal_code)

address = current_user.address || current_user.build_address
address.assign_attributes(
  line1:       @order.shipping_address,
  city:        city,
  postal_code: postal_code,
  province_id: province_record.id
)
address.name = @order.shipping_name if address.respond_to?(:name=)

    begin
      address.save!
    rescue ActiveRecord::RecordInvalid => e
      return prepare_failed_new(cart_items, "Address error: #{e.record.errors.full_messages.to_sentence}")
    end

    @order.address = address

    subtotal   = cart_items.sum { |i| i.quantity * i.product.price }
    tax_rate   = tax_rate_for(@order.province)
    tax_amount = subtotal * tax_rate
    total      = subtotal + tax_amount

    @order.subtotal = subtotal
    @order.tax      = tax_amount
    @order.total    = total
    @order.status ||= "pending"

    if @order.save
      cart_items.find_each do |i|
        @order.order_items.create!(product: i.product, quantity: i.quantity, unit_price: i.product.price)
      end
      cart_items.destroy_all

      stripe_session = Stripe::Checkout::Session.create(
        payment_method_types: ['card'],
        customer_email: current_user.email,
        line_items: @order.order_items.map { |item|
          { price_data: { currency: 'cad',
                          product_data: { name: item.product.name },
                          unit_amount: (item.unit_price * 100).to_i },
            quantity: item.quantity }
        },
        mode: 'payment',
        success_url: success_checkout_url + "?session_id={CHECKOUT_SESSION_ID}",
        cancel_url:  cancel_checkout_url
      )

      @order.update(stripe_session_id: stripe_session.id)
      redirect_to stripe_session.url, allow_other_host: true
    else
      prepare_failed_new(cart_items, "Please check the form.")
    end
  rescue Stripe::StripeError => e
    prepare_failed_new(current_user.cart_items.includes(:product), "Payment error: #{e.message}")
  end

  def success
    session = Stripe::Checkout::Session.retrieve(params[:session_id])
    order   = Order.find_by(stripe_session_id: session.id)
    if order && order.status != "paid"
      order.update(status: "paid", stripe_payment_id: session.payment_intent)
    end
    redirect_to order_path(order), notice: "Payment successful!"
  end

  def cancel
    redirect_to orders_path, alert: "Payment was canceled."
  end

  # 👇 keep this PUBLIC (above `private`)
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
    ship_to = [shipping_address, city, province_name, postal_code].reject(&:blank?).join(", ")
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

  def order_params
    params.fetch(:order, {}).permit(:shipping_name, :shipping_address, :province)
  end

  def tax_rate_for(province_name)
    {
      "Manitoba" => 0.12, "Ontario" => 0.13, "Quebec" => 0.14975, "Alberta" => 0.05,
      "Saskatchewan" => 0.11, "British Columbia" => 0.12, "Nova Scotia" => 0.15,
      "New Brunswick" => 0.15, "Prince Edward Island" => 0.15,
      "Newfoundland and Labrador" => 0.15
    }[province_name] || 0
  end

  def prepare_failed_new(cart_items, message = nil)
    @provinces  = PROVINCES
    @cart_items = cart_items
    @orders     = current_user.orders.order(created_at: :desc).limit(5)
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
