class AddReviewsCountToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :reviews_count, :integer
  end
end
