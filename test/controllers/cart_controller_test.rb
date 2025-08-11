require "test_helper"

class CartControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = User.find_or_create_by!(email: "shopper@test.local") do |u|
      u.password = "password123"
      u.username = "shopper"
      u.role     = "customer"
    end
    sign_in @user, scope: :user

    @category = Category.find_or_create_by!(name: "Vitamins")
    @product  = Product.find_or_create_by!(name: "Cart Test Product", category: @category) { |p| p.price = 5.55 }
  end

  test "should get show" do
    get cart_url
    assert_response :success
  end

  test "should add item" do
    post add_item_cart_url(product_id: @product.id)
    assert_redirected_to cart_url
  end

  test "should remove item" do
    post add_item_cart_url(product_id: @product.id)
    delete remove_item_cart_url(product_id: @product.id)
    assert_redirected_to cart_url
  end
end
