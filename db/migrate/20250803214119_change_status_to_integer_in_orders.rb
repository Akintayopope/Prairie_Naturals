class ChangeStatusToIntegerInOrders < ActiveRecord::Migration[7.0]
  def up
    # Remove the default string
    change_column_default :orders, :status, nil

    # Convert existing 'pending' string values to integer '0'
    execute <<-SQL.squish
      UPDATE orders SET status = '0' WHERE status = 'pending';
    SQL

    # Change column type from string to integer
    change_column :orders, :status, 'integer USING CAST(status AS integer)'

    # Set the new default to 0 (pending)
    change_column_default :orders, :status, 0
  end

  def down
    change_column_default :orders, :status, nil
    change_column :orders, :status, :string
    change_column_default :orders, :status, 'pending'
  end
end
