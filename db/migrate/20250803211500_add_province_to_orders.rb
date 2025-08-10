class AddProvinceToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :province, :string
  end
end
