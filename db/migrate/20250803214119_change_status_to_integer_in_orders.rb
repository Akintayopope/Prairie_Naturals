class ChangeStatusToIntegerInOrders < ActiveRecord::Migration[7.0]
  def up
    change_column_default :orders, :status, nil
    execute "UPDATE orders SET status = '0' WHERE status = 'pending';"
    change_column :orders, :status, 'integer USING CAST(status AS integer)'
    change_column_default :orders, :status, 0
  end

  def down
    change_column_default :orders, :status, nil
    change_column :orders, :status, :string
    change_column_default :orders, :status, 'pending'
  end
end

