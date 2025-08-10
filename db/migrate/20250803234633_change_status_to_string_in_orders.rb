class ChangeStatusToStringInOrders < ActiveRecord::Migration[7.0]
  def up
    change_column :orders, :status, :string, using: 'status::text'
    change_column_default :orders, :status, 'pending'
  end

  def down
    change_column :orders, :status, :integer, using: 'status::integer'
    change_column_default :orders, :status, 0
  end
end
