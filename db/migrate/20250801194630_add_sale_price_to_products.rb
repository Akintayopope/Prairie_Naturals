class AddSalePriceToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :sale_price, :decimal
  end
end
