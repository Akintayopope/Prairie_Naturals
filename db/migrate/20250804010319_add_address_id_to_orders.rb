class AddAddressIdToOrders < ActiveRecord::Migration[7.0]
  def change
    unless column_exists?(:orders, :address_id)
      add_reference :orders, :address, null: false, foreign_key: true
    end
  end
end
