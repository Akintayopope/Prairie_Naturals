class AddImageUrlToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :image_url, :string unless column_exists?(:products, :image_url)
  end
end
