class RemoveOrderIdFromAddresses < ActiveRecord::Migration[7.0] # adjust if you're using a different version
  def change
    remove_column :addresses, :order_id, :integer
  end
end
