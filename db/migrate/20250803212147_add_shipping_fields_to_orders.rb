class AddShippingFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :shipping_name, :string
    add_column :orders, :shipping_address, :text
    # add_column :orders, :province, :string
  end
end
