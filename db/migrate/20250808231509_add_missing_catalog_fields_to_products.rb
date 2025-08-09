class AddMissingCatalogFieldsToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :rating, :decimal, precision: 3, scale: 1
    add_column :products, :image_url, :string
    add_column :products, :link, :string

    change_column :products, :price, :decimal, precision: 10, scale: 2
  end
end
