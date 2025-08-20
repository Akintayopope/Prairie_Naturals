# app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!

  def index
    @orders =
      current_user
        .orders
        .includes(order_items: :product, address: :province)
        .order(created_at: :desc)
  end

  def show
    @order =
      current_user
        .orders
        .includes(order_items: :product, address: :province)
        .find(params[:id])
  end

  def new
    @order = current_user.orders.new
  end

  def create
    @order = current_user.orders.new(order_params)

    if @order.save
      flash[:success] = "Order placed successfully. 🎉"
      redirect_to @order
    else
      flash.now[:warning] = "Please fix the errors below."
      render :new, status: :unprocessable_entity
    end
  end

  def receipt
    @order = current_user.orders.find(params[:id])

    respond_to do |format|
      format.html do
        redirect_to order_path(@order),
                    notice: "Use the PDF button to download your receipt."
      end
      format.pdf do
        disposition = params[:dl].present? ? "attachment" : "inline"
        send_data build_receipt_pdf(@order),
                  filename: "Receipt-#{@order.id}.pdf",
                  type: "application/pdf",
                  disposition: disposition
      end
    end
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
    pdf.text "Date: #{@order.created_at.strftime("%B %d, %Y")}"
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
            "$#{format("%.2f", item.unit_price)}",
            "$#{format("%.2f", (item.unit_price * item.quantity))}"
          ]
        end,
      header: true,
      width: pdf.bounds.width
    )

    pdf.move_down 20
    pdf.text "Subtotal: $#{format("%.2f", @order.subtotal)}"
    pdf.text "Tax: $#{format("%.2f", @order.tax)}"
    pdf.text "Total: $#{format("%.2f", @order.total)}", style: :bold

    send_data pdf.render,
              filename: "invoice_order_#{@order.id}.pdf",
              type: "application/pdf",
              disposition: "inline"
  end

  # app/controllers/orders_controller.rb

  private

  def build_receipt_pdf(order)
    require "prawn"

    h = view_context # Rails helpers

    paid_on =
      order.try(:paid_at) ||
        (order.status.to_s == "paid" ? order.updated_at : nil) ||
        order.created_at
    subtotal =
      (order.try(:subtotal) || order.try(:subtotal_cents).to_i / 100.0).to_f
    tax = (order.try(:tax) || order.try(:tax_cents).to_i / 100.0).to_f
    total = (order.try(:total) || order.try(:total_cents).to_i / 100.0).to_f
    gst = (order.try(:gst_cents).to_i / 100.0).to_f
    pst = (order.try(:pst_cents).to_i / 100.0).to_f
    hst = (order.try(:hst_cents).to_i / 100.0).to_f

    brand = order.try(:payment_brand) || order.try(:card_brand) || "Card"
    last4 = order.try(:payment_last4) || order.try(:card_last4)
    intent =
      order.try(:payment_intent_id) || order.try(:stripe_payment_intent_id)
    charge = order.try(:charge_id) || order.try(:stripe_charge_id)
    curr = (order.try(:currency) || "CAD").to_s.upcase

    Prawn::Document
      .new(page_size: "A4", margin: 36) do |pdf|
        # Header
        pdf.text "Receipt", size: 20, style: :bold
        pdf.move_down 4
        pdf.text "Order ##{order.id}"
        pdf.text "Paid on: #{paid_on.in_time_zone.strftime("%B %d, %Y %l:%M %p")}"

        pdf.move_down 8
        pdf.text "Prairie Naturals", style: :bold
        pdf.text "Winnipeg, MB, Canada"

        pdf.move_down 16

        # Two columns: Billed To / Payment
        left = []
        left << "Billed To"
        left << order.shipping_name.to_s
        if order.address
          left << order.address.full_address.to_s
        else
          left << order.shipping_address.to_s
          left << [
            order.try(:city),
            order.try(:postal_code),
            order.try(:province)
          ].compact.join(", ")
        end

        right = []
        right << "Payment"
        right << "#{brand.to_s.titleize}#{last4.present? ? " •••• #{last4}" : ""}"
        right << "Currency: #{curr}"
        right << "PI: #{intent}" if intent.present?
        right << "Charge: #{charge}" if charge.present?

        # draw two side-by-side text boxes without tables
        col_gap = 18
        left_w = (pdf.bounds.width - col_gap) * 0.6
        right_w = (pdf.bounds.width - col_gap) * 0.4

        y0 = pdf.cursor
        pdf.bounding_box([pdf.bounds.left, y0], width: left_w) do
          left.each { |l| pdf.text l }
        end
        pdf.bounding_box(
          [pdf.bounds.left + left_w + col_gap, y0],
          width: right_w
        ) { right.each { |r| pdf.text r } }
        pdf.move_down 16

        # Line items (monospace for alignment)
        # Line items (monospace for alignment)
        pdf.font("Courier")

        def row_line(name, qty, unit, total)
          sprintf(
            "%-44.44s %-6s %12s %12s",
            name.to_s,
            qty.to_s,
            unit.to_s,
            total.to_s
          )
        end

        pdf.text row_line("Item", "Qty", "Unit", "Total"), style: :bold
        pdf.stroke_horizontal_rule
        pdf.move_down 2

        order.order_items.each do |li|
          # --- SAFE NAME / PRICES (no product_name needed) ---
          name =
            if li.respond_to?(:name) && li.name.present?
              li.name
            elsif li.respond_to?(:product) && li.product.present?
              li.product.name
            else
              "Item ##{li.product_id || li.id}"
            end

          qty = li.respond_to?(:quantity) ? li.quantity.to_i : 1

          unit_price =
            if li.respond_to?(:unit_price_cents) && li.unit_price_cents.present?
              li.unit_price_cents.to_i / 100.0
            elsif li.respond_to?(:unit_price) && li.unit_price.present?
              li.unit_price.to_f
            else
              0.0
            end

          line_total =
            if li.respond_to?(:total_price_cents) &&
                 li.total_price_cents.present?
              li.total_price_cents.to_i / 100.0
            elsif li.respond_to?(:total_price) && li.total_price.present?
              li.total_price.to_f
            else
              unit_price * qty
            end

          unit = h.number_to_currency(unit_price)
          line = h.number_to_currency(line_total)

          pdf.text row_line(name, qty, unit, line)
        end

        # Back to normal font for totals
        pdf.font("Helvetica")

        pdf.move_down 12

        # Totals block aligned to the right
        right_box_w = 220
        pdf.bounding_box(
          [pdf.bounds.right - right_box_w, pdf.cursor],
          width: right_box_w
        ) do
          lines = []
          lines << ["Subtotal", h.number_to_currency(subtotal)]
          tax_label = "Tax"
          tax_label += " (#{order.province})" if order.province.present?
          lines << [tax_label, h.number_to_currency(tax)]
          lines << ["• GST", h.number_to_currency(gst)] if gst.positive?
          lines << ["• PST", h.number_to_currency(pst)] if pst.positive?
          lines << ["• HST", h.number_to_currency(hst)] if hst.positive?
          lines << ["Total Paid", h.number_to_currency(total)]

          # simple two-column right-aligned second column
          lines.each_with_index do |(label, val), i|
            pdf.text "#{label}"
            pdf.text "#{val}", align: :right
            pdf.move_down(4) unless i == lines.length - 1
          end
          pdf.stroke_horizontal_rule
        end

        pdf.move_down 12
        pdf.text "Thank you for your purchase!", size: 10
      end
      .render
  end

  # Strong params
  def order_params
    params.require(:order).permit(
      :shipping_name,
      :shipping_address,
      :billing_address,
      :province_id,
      :postal_code,
      :phone,
      :status,
      order_items_attributes: %i[id product_id quantity unit_price _destroy],
      address_attributes: %i[
        id
        line1
        line2
        city
        province_id
        postal_code
        _destroy
      ]
    )
  end
end
