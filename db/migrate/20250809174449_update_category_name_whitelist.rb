# db/migrate/20250811_update_category_name_whitelist.rb
class UpdateCategoryNameWhitelist < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      ALTER TABLE categories
      DROP CONSTRAINT IF EXISTS categories_name_whitelist;

      ALTER TABLE categories
      ADD CONSTRAINT categories_name_whitelist
      CHECK (name IN ('Vitamins','Skin Care','Supplements'));
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE categories
      DROP CONSTRAINT IF EXISTS categories_name_whitelist;

      ALTER TABLE categories
      ADD CONSTRAINT categories_name_whitelist
      CHECK (name IN ('Vitamins','Skin Care')); -- revert to previous set
    SQL
  end
end
