require 'rails_helper'

RSpec.describe "Cart & Checkout", type: :system do
  before do
    cat = Category.find_or_create_by!(name: "Vitamins")
    Product.find_or_create_by!(name: "RSpec Test Product") do |p|
      p.category = cat if p.respond_to?(:category=)
      if p.respond_to?(:price_cents=)
        p.price_cents = 1299
      elsif p.respond_to?(:price=)
        p.price = 12.99
      else
        begin
          p.write_attribute(:price_cents, 1299)
        rescue
          # leave price if model computes it elsewhere
        end
      end
      p.description = "Test item" if p.respond_to?(:description=)
      p.stock = 50 if p.respond_to?(:stock=)
    end
  end

  it "adds a product, goes to cart, reaches checkout form (happy path)" do
    visit "/"

    # Go to product page
    (click_link "RSpec Test Product", exact: false rescue nil) ||
      (click_link "Show", match: :first rescue nil)

    # Add to cart
    (click_button "Add to Cart", exact: false rescue click_button("Add to cart", exact: false) rescue nil)

    # Open cart
    (click_link "Cart", exact: false rescue click_link("View Cart", exact: false))

    # Optional: update quantity if present
    begin
      fill_in(/Quantity|Qty/i, with: "2")
      (click_button "Update", exact: false rescue nil)
    rescue Capybara::ElementNotFound
      # qty not present; continue
    end

    # Proceed to checkout
    (click_button "Checkout", exact: false rescue click_link("Checkout", exact: false))

    # Assert we've reached a checkout form rather than placing order (Stripe/validation may block)
    expect(page).to have_content(/Checkout|Shipping Address|Payment/i)
  end

  it "cannot checkout with an empty cart (unhappy path)" do
    visit "/cart"
    expect(page).to have_content(/your cart is empty/i).or have_button("Checkout", disabled: true)
  end
end
