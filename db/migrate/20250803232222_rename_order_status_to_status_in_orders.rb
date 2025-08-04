class RenameOrderStatusToStatusInOrders < ActiveRecord::Migration[8.0]
  def change
    rename_column :orders, :order_status, :status
  end
end
