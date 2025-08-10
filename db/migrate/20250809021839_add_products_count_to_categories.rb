class AddProductsCountToCategories < ActiveRecord::Migration[7.1]
  def up
    add_column :categories, :products_count, :integer, default: 0, null: false

    # Backfill existing counts (safe if empty; fast enough for dev)
    say_with_time "Backfilling categories.products_count" do
      Category.reset_column_information
      Category.find_each { |c| Category.reset_counters(c.id, :products) }
    end
  end

  def down
    remove_column :categories, :products_count
  end
end
