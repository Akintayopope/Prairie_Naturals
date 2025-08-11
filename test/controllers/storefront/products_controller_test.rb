require "test_helper"
require "securerandom"

class Storefront::ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Build a valid user for your app (adjust fields if your users table requires more)
    cols = User.column_names
    attrs = {
      email: "ci_admin@example.com",
      password: "Password123!",
      password_confirmation: "Password123!"
    }
    attrs[:username]     = "ciadmin"   if cols.include?("username")   # your app requires it
    attrs[:name]         = "CI Admin"  if cols.include?("name")
    attrs[:confirmed_at] = Time.current if cols.include?("confirmed_at") # Devise confirmable
    attrs[:role]         = "admin"     if cols.include?("role")
    attrs[:admin]        = true        if cols.include?("admin")

    @user = User.find_by(email: attrs[:email]) || User.create!(attrs)
    sign_in @user

    @category = Category.find_or_create_by!(name: "Vitamins", slug: "vitamins") do |c|
      c.products_count = 0
    end

    @product = Product.create!(
      name:  "Controller Test Product #{SecureRandom.hex(4)}",
      title: "Controller Test Product",
      price: 9.99,
      stock: 5,
      category: @category
    )
  end

  test "should get index" do
    get storefront_products_url
    assert_response :success
    assert_includes @response.body, @product.name
  end

  test "should get show" do
    get storefront_product_url(@product)
    assert_response :success
    assert_includes @response.body, @product.name
  end
end
