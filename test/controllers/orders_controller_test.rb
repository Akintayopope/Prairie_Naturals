# test/controllers/orders_controller_test.rb
require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    # --- User ---
    @user = User.find_or_create_by!(email: "orders-test@example.com") do |u|
      u.password = "password123"
      u.username = "orders_tester" if u.respond_to?(:username=)
      u.role     = "customer"      if u.respond_to?(:role=)
    end
    sign_in @user, scope: :user

    # --- Province record (association or lookup) ---
    @province_rec =
      if defined?(Province)
        key = Province.column_names.include?("code") ? { code: "MB" } : { name: "Manitoba" }
        Province.find_or_create_by!(**key) do |p|
          p.name = "Manitoba" if p.respond_to?(:name=) && p.name.blank?
          p.gst  = 0.05 if p.respond_to?(:gst=)
          p.pst  = 0.07 if p.respond_to?(:pst=)
          p.hst  = 0.00 if p.respond_to?(:hst=)
          p.tax_rate = 0.12 if p.respond_to?(:tax_rate=)
        end
      end

    order_cols = Order.column_names

    # --- Address (only if Order belongs_to :address) ---
    if Order.reflect_on_association(:address)
      address_cols = Address.column_names
      a = {}

      # user link if present
      a[:user_id] = @user.id if address_cols.include?("user_id")

      # name fields
      if address_cols.include?("name")
        a[:name] = "John Doe"
      else
        a[:first_name] = "John" if address_cols.include?("first_name")
        a[:last_name]  = "Doe"  if address_cols.include?("last_name")
      end

      # line1/line2 variants
      a[:line1]     = "123 Main St" if address_cols.include?("line1")
      a[:address1]  = "123 Main St" if address_cols.include?("address1")
      a[:street]    = "123 Main St" if address_cols.include?("street")
      a[:street1]   = "123 Main St" if address_cols.include?("street1")
      a[:address]   = "123 Main St" if address_cols.include?("address") && !address_cols.include?("line1") && !address_cols.include?("address1")

      # city
      a[:city] = "Winnipeg" if address_cols.include?("city")

      # province/state variants
      if address_cols.include?("province_id") && @province_rec
        a[:province_id] = @province_rec.id
      elsif address_cols.include?("province")
        a[:province] = "Manitoba"
      elsif address_cols.include?("state")
        a[:state] = "MB"
      elsif address_cols.include?("region")
        a[:region] = "MB"
      end

      # postal variants (this fixes your error)
      if address_cols.include?("postal_code")
        a[:postal_code] = "R3C0X0"
      elsif address_cols.include?("postal")
        a[:postal] = "R3C0X0"
      elsif address_cols.include?("zip")
        a[:zip] = "R3C0X0"
      elsif address_cols.include?("postcode")
        a[:postcode] = "R3C0X0"
      end

      # country variants
      a[:country]       = "Canada" if address_cols.include?("country")
      a[:country_code]  = "CA"     if address_cols.include?("country_code")

      # phone if required
      a[:phone]         = "2045551234" if address_cols.include?("phone")
      a[:phone_number]  = "2045551234" if address_cols.include?("phone_number")

      @address = Address.create!(**a)
    end

    # --- Status handling (enum hash, array, or plain string) ---
    status_value = nil
    if Order.respond_to?(:statuses)
      sts = Order.statuses
      if sts.is_a?(Hash)
        status_value = sts.key?("pending") ? "pending" : sts.keys.first
      elsif sts.is_a?(Array)
        status_value = sts.include?("pending") ? "pending" : sts.first
      end
    end
    status_value ||= "pending" if order_cols.include?("status")

    # --- Build Order attributes from actual schema ---
    o = {}
    o[:user] = @user if order_cols.include?("user_id")

    # Province on order (association, id, or string)
    if Order.reflect_on_association(:province) && @province_rec
      o[:province] = @province_rec
    elsif order_cols.include?("province_id") && @province_rec
      o[:province_id] = @province_rec.id
    elsif order_cols.include?("province")
      o[:province] = "Manitoba"
    end

    # Address association if present
    o[:address] = @address if Order.reflect_on_association(:address)

    # Status if column exists
    o[:status] = status_value if status_value && order_cols.include?("status")

    # Shipping/generic fields (only if present)
    o[:shipping_name]    = "John Doe"    if order_cols.include?("shipping_name")
    o[:shipping_address] = "123 Main St" if order_cols.include?("shipping_address")
    o[:name]             = "John Doe"    if order_cols.include?("name")    && !order_cols.include?("shipping_name")
    o[:address]          = "123 Main St" if order_cols.include?("address") && !order_cols.include?("shipping_address")

    @order = Order.create!(**o)
  end

  test "should get show" do
    get order_url(@order)
    assert_response :success
  end
end
