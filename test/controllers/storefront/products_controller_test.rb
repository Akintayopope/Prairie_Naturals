# test/controllers/storefront/products_controller_test.rb
require "test_helper"

class Storefront::ProductsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @category = Category.create!(name: "Vitamins")
    @product  = Product.create!(name: "Test Product", price: 9.99, category: @category)

    @user = User.create!(email: "shopper@test.local", password: "password123", username: "shopper", role: "customer")
    sign_in @user, scope: :user
  end

  test "should get index" do
    get storefront_products_url
    assert_response :success
  end

  test "should get show" do
    get storefront_product_url(@product)
    assert_response :success
  end
end
