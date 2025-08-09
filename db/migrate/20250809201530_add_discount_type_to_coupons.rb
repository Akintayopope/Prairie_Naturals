class AddDiscountTypeToCoupons < ActiveRecord::Migration[7.1]
  def change
    add_column :coupons, :discount_type, :integer, default: 0, null: false
  end
end
