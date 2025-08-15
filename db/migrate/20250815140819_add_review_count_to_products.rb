class AddReviewCountToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :review_count, :integer, default: 0, null: false
    # (Optional) if you want to cap rating to one decimal place in the DB:
    change_column :products, :rating, :decimal, precision: 3, scale: 1
  end
end
