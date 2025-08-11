# test/controllers/products_controller_test.rb
require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin@test.local") do |u|
      u.password = "password123"
      u.username = "admin"
      u.role     = "admin"
    end
    sign_in @admin, scope: :user

    @category = Category.find_or_create_by!(name: "Vitamins")
    @product  = Product.find_or_create_by!(name: "Test Product", category: @category) do |p|
      p.price = 9.99
      p.stock = 10
    end
  end

  test "index success" do
    get products_url
    assert_response :success
  end

  test "show success via friendly id" do
    get product_url(@product) # works with id or slug
    assert_response :success
  end

  test "update keeps slug stable and redirects to original slug" do
    original_path = product_path(@product)
    patch product_url(@product), params: { product: { name: "Updated Name" } }
    assert_redirected_to original_path
    assert_equal "Updated Name", @product.reload.name
  end

  test "index renders Add to Cart button with correct route" do
    get products_url
    assert_response :success
    # Ensure the singular cart helper is used
    assert_select "form[action='#{add_item_cart_path(product_id: @product.id)}'][method='post']", true
  end
end
