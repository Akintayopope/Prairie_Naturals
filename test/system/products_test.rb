# test/system/products_test.rb
# at top
require "securerandom"

# in setup:
@product = Product.create!(
  name:  "Sample Product #{SecureRandom.hex(4)}",
  title: "Sample Product",
  price: 9.99,
  stock: 10,
  category: @category
)

# in "should create product":
Product.create!(
  name:  "New Test Product #{SecureRandom.hex(4)}",
  title: "New Test Product",
  price: 12.34,
  stock: 5,
  category: @category
)


# frozen_string_literal: true
require "application_system_test_case"

class ProductsTest < ApplicationSystemTestCase
  def login_admin!
  cols = User.column_names

  attrs = {
    email:                 "ci_admin@example.com",
    password:              "Password123!",
    password_confirmation: "Password123!"
  }

  # Fill any common required fields if they exist in your schema
  attrs[:username]     = "ci_admin"         if cols.include?("username")
  attrs[:name]         = "CI Admin"         if cols.include?("name")
  attrs[:first_name]   = "CI"               if cols.include?("first_name")
  attrs[:last_name]    = "Admin"            if cols.include?("last_name")
  attrs[:confirmed_at] = Time.current       if cols.include?("confirmed_at") # Devise Confirmable

  # Admin role/flag (support either enum role or boolean admin)
  if User.respond_to?(:roles) && User.roles.is_a?(Hash) && User.roles.key?("admin")
    attrs[:role] = "admin"
  elsif cols.include?("role")
    attrs[:role] = "admin" # plain string role column
  end
  attrs[:admin] = true if cols.include?("admin")

  # Terms / agreements (just in case)
  attrs[:terms_accepted]  = true if cols.include?("terms_accepted")
  attrs[:accept_terms]    = true if cols.include?("accept_terms")
  attrs[:agreed_to_terms] = true if cols.include?("agreed_to_terms")

  @admin = User.find_by(email: attrs[:email]) || User.create!(attrs)
  login_as @admin, scope: :user
end


  def visit_storefront!
    if defined?(storefront_products_path)
      visit storefront_products_path
    else
      visit "/storefront/products"
    end
  end

  setup do
    login_admin!

    # Satisfy categories_name_whitelist
    @category = Category.find_by(name: "Vitamins") ||
                Category.create!(name: "Vitamins", slug: "vitamins", products_count: 0)

    @product = Product.create!(
      name:  "Sample Product",
      title: "Sample Product",
      price: 9.99,
      stock: 10,
      category: @category
    )
  end

  test "visiting the index" do
    visit_storefront!
    assert_selector "h1", text: /Our Products/i
  end

  test "should create product" do
    Product.create!(
      name: "New Test Product",
      title: "New Test Product",
      price: 12.34,
      stock: 5,
      category: @category
    )
    visit_storefront!
    assert_text "New Test Product"
  end

  test "should update Product" do
    @product.update!(name: "Updated Name", price: 10.00)
    assert_equal "Updated Name", @product.reload.name
  end

  test "should destroy Product" do
    @product.destroy!
    refute Product.exists?(@product.id)
  end
end
