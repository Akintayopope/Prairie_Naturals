# test/controllers/checkout_controller_test.rb
require "test_helper"

class CheckoutControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # User (Devise)
    @user = User.find_or_create_by!(email: "buyer@test.local") do |u|
      u.password = "password123"
      u.username = "buyer"     if u.respond_to?(:username=)
      u.role     = "customer"  if u.respond_to?(:role=)
    end
    sign_in @user, scope: :user

    # Product
    @category = Category.find_or_create_by!(name: "Vitamins")
    @product  = Product.find_or_create_by!(name: "Checkout Product") do |p|
      p.category = @category
      p.price    = 4.99
      p.stock    = 10 if p.respond_to?(:stock=)
    end

    # Seed the user's cart (your controller uses current_user.cart_items)
    raise "CartItem model missing" unless defined?(CartItem)
    cic = CartItem.column_names
    ci  = { product_id: @product.id }
    ci[:user_id]  = @user.id if cic.include?("user_id")
    ci[:quantity] = 1        if cic.include?("quantity")
    CartItem.create!(**ci)

    # Province record looked up by name
    @province = Province.find_or_create_by!(name: "Ontario")
  end

  test "should get new" do
    get new_checkout_path
    assert_response :success, "Expected 200 OK, got #{response.status} (body: #{response.body&.first(200)})"
  end

  test "should create" do
    params = {
      order: {
        shipping_name:    "Jane Buyer",
        shipping_address: "123 Test St",
        province:         "Ontario",
        city:             "Toronto",
        postal_code:      "M1A1A1"
      }
    }

    # Manually stub Stripe::Checkout::Session.create
    klass = Stripe::Checkout::Session
    original = klass.method(:create)
    fake_session = Struct.new(:id, :url).new("sess_test_123", "https://example.com/stripe/checkout")

    begin
      klass.define_singleton_method(:create) { |_h| fake_session }

      post checkout_path, params: params
      assert_response :redirect, "Expected redirect, got #{response.status} (body: #{response.body&.first(300)})"
    ensure
      # Restore original method
      klass.define_singleton_method(:create, original)
    end
  end
end
