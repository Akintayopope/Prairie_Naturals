class AddStripeFieldsToOrders < ActiveRecord::Migration[7.0]
  def change
    add_column :orders, :stripe_session_id, :string
    add_column :orders, :stripe_payment_id, :string
  end
end
